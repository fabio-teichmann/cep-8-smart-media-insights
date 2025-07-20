import os
import boto3
import json
import base64
from datetime import datetime
import logfire
from botocore.exceptions import ClientError
from boto3.dynamodb.types import TypeSerializer

serializer = TypeSerializer()

logfire.configure()

dynamo_client = boto3.client("dynamodb")
DYNAMO_TABLE = os.getenv("DYNAMO_TABLE")

comprehend_client = boto3.client("comprehend")
s3_client = boto3.client("s3")


def lambda_handler(event, context):
    for record in event["Records"]:
        logfire.debug(f"RECORD: {record}")
        # extract params
        s3_bucket = record["s3"]["bucket"]["name"]
        key_to_obj = record["s3"]["object"]["key"]
        request_id = key_to_obj.split("/")[-1].split("_")[0]
        try:
            file = s3_client.get_object(
                Bucket = s3_bucket,
                Key = key_to_obj
            )
            logfire.debug(f"FILE metadata from S3: {file['Metadata']}")
            logfire.debug(f"FILE from S3: {file}")
            text = file.get("Body").read().decode("utf-8")
            logfire.info(f"TEXT: {text}")

            # payload = base64.b64decode(record["s3"]["data"]).decode("utf-8")
            # media_meta = json.loads(payload)
            # logfire.info("Decoded metadata", extra=media_meta)
        except ClientError as e:
            logfire.error(f"S3 client error: {e}")
            return {
                "statusCode": 500,
                "message": str(e),
            }
        
        try:
            response = comprehend_client.detect_sentiment(
                Text = text,
                LanguageCode = "en"
            )
            logfire.info("Comprehend sentiment detection success", extra=response)
            media_status = "processed"
            result = {
                "sentiment": response["Sentiment"],
                "sentiment_score": response["SentimentScore"],
            }
            serialized_result = serializer.serialize(result)

        except ClientError as e:
            logfire.error(f"Comprehend client error: {e}")
            return {
                "statusCode": 500,
                "message": str(e),
            }
        except Exception as e:
            logfire.error(f"General error: {e}")
            return {
                "statusCode": 500,
                "message": str(e),
            }
        
        logfire.info("Updating entry in DynamoDB...")
        item = {
            # "request_id": {"S": request_id},
            "updated_at": {"S": datetime.now().isoformat()},
            "status": {"S": media_status},
            # "media_type": {"S": "text"},
            "result": serialized_result
        }
        try:
            response = dynamo_client.update_item(
                TableName=DYNAMO_TABLE,
                Key={"request_id": {"S": request_id}},
                UpdateExpression="SET",
                ExpressionAttributeValues=item,
                # AttributeUpdates=item,
                # Item=item,
            )
        except ClientError as e:
            logfire.error(f"DynamoDB client error: {e}")
            return {
                "statusCode": 500,
                "message": str(e),
            }
        except Exception as e:
            logfire.error(f"General error: {e}")
            return {
                "statusCode": 500,
                "message": str(e),
            }

    return {
        "statusCode": 200,
        "message": "All records processed successfully"
    }

logfire.instrument_aws_lambda(lambda_handler)
