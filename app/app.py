import os 
from uuid import uuid4
from datetime import datetime
from fastapi import Response, status, File, UploadFile
from fastapi.responses import JSONResponse

import boto3
from botocore.exceptions import ClientError
import logfire

from helpers import create_app
from models import MediaMeta, MediaUploadResponse

AWS_REGION = os.getenv("AWS_REGION")
DYNAMO_TABLE = os.getenv("DYNAMO_TABLE_NAME")
KDS_STREAM_NAME = os.getenv("KDS_STREAM_NAME")
S3_MEDIA_BUCKET = os.getenv("S3_MEDIA_BUCKET")

dynamo_client = boto3.client("dynamodb", region_name=AWS_REGION)
kds_client = boto3.client("kinesis", region_name=AWS_REGION)
s3_client = boto3.client("s3", region_name=AWS_REGION)

app = create_app()

@app.get("/health")
def health_check():
    return JSONResponse(content={"status": "ok"})

@app.post("/upload-media", response_model=MediaUploadResponse, status_code=status.HTTP_202_ACCEPTED)
async def upload_media(response: Response, file: UploadFile = File(...)) -> str:
    """uploads media file to S3 bucket and returns a request id to fetch results"""
    request_id = uuid4()

    logfire.info(f"media_type: {file.content_type}")
    # check media type (text vs. image)
    if file.content_type.startswith("image/"):
        media_type = "image"
    elif file.content_type == "text/plain":
        media_type = "text"
    else:
        response.status_code = status.HTTP_400_BAD_REQUEST
        return {"error": "unsupported media type"}
    
    s3_key = f"uploads/{media_type}/{request_id}_{file.filename}"
    
    try:
        logfire.info("uploading file to S3...")
        r = s3_client.put_object(
            Bucket=S3_MEDIA_BUCKET,
            Body=await file.read(),
            Key=s3_key,
            ContentType = file.content_type
        )
        logfire.debug(f"s3 upload response: {r}")
    except ClientError as e:
        response.status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
        logfire.error(f"S3 client error: {e}")
        return {"error": str(e)}
    
    
    # create metadata object to write initial DynamoDB entry (post-Kinesis)
    meta = MediaMeta(
        request_id=request_id,
        created_at=datetime.now().isoformat(),
        status="accepted",
        media_type=media_type,
    )
    logfire.debug(f"metadata obj: {meta}")
    try:
        logfire.info("sending metadata to kinesis...")
        # send metadata to Kinesis
        r = kds_client.put_record(
            StreamName=KDS_STREAM_NAME,
            Data=meta.model_dump_json().encode("utf-8"),
            PartitionKey="test",
        )
        logfire.debug(f"kinesis response: {r}")
    except ClientError as e:
        response.status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
        logfire.error(f"KDS client error: {e}")
        return e
    logfire.info("all steps completed...")
    return MediaUploadResponse(request_id=str(request_id))
    

@app.get("/results/{request_id}", status_code=status.HTTP_200_OK)
def get_results(request_id: str, response: Response):
    """checks results' status and retrieves results if processed"""
    logfire.info(f"Checking results for request: {request_id}...")
    try:
        logfire.debug("--> sending request to DynamoDB...")
        r = dynamo_client.get_item(
            TableName = DYNAMO_TABLE,
            Key = {
                "request_id": {
                    "S": request_id,
                }
            }
        )
        logfire.debug(f"Dynamo response: {r}")
    except ClientError as e:
        logfire.error(f"Dynamo client error: {e}")
        response.status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
        return {"error": e} 
    except Exception as e:
        logfire.error(f"error: {e}")
        response.status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
        return {"error": e} 
    
    item = r.get("Item")
    if not item or "status" not in item:
        response.status_code = status.HTTP_404_NOT_FOUND
        logfire.error("Result not found or incomplete")
        return {"error": "Result not found or incomplete"}
        
    request_status = item["status"]["S"]

    if request_status == "failed":
        logfire.error("failed to process media")
        response.status_code = status.HTTP_422_UNPROCESSABLE_ENTITY
        return {"error": "failed to process media"}

    elif request_status == "processed":
        logfire.info("media processed successfully!")
        return r["Item"]
    
    elif request_status == "processing":
        logfire.info("media is still being processed")
        response.status_code = status.HTTP_202_ACCEPTED

    else:
        logfire.warn(f"status: {request_status}")
        response.status_code = status.HTTP_400_BAD_REQUEST
    