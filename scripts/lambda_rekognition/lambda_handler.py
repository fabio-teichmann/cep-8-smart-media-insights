import os
import boto3
import json
import base64
from datetime import datetime
from decimal import Decimal

import logfire
from botocore.exceptions import ClientError
from boto3.dynamodb.types import TypeSerializer

serializer = TypeSerializer()

logfire.configure()

dynamo_client = boto3.client("dynamodb")
DYNAMO_TABLE = os.getenv("DYNAMO_TABLE")

rekognition_client = boto3.client("rekognition")
s3_client = boto3.client("s3")


def lambda_handler(event, context):
    for record in event["Records"]:
        logfire.debug(f"RECORD: {record}")
        # extract params
        s3_bucket = record["s3"]["bucket"]["name"]
        key_to_obj = record["s3"]["object"]["key"]
        request_id = key_to_obj.split("/")[-1].split("_")[0]
        
        try:
            response = rekognition_client.detect_labels(
                Image={'S3Object':{'Bucket': s3_bucket,'Name': key_to_obj}},
                MaxLabels=5,
            )
     
            logfire.info("Rekognition label detection success", extra=response)
            media_status = "processed"
            result = {}
            for i, label in enumerate(response["Labels"]):
                vals = (label["Name"], str(label["Confidence"]))
                result[f"label_{i + 1}"] = vals

            logfire.debug(f"RESULT: {result}")
            serialized_result = serializer.serialize(result)
            logfire.debug(f"SERIALIZED: {serialized_result}")

        except ClientError as e:
            logfire.error(f"Rekognition client error: {e}")
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
            ":updated_at": {"S": datetime.now().isoformat()},
            ":status": {"S": media_status},
            ":result": serialized_result
        }
        logfire.debug(f"ITEM: {item}")
        try:
            response = dynamo_client.update_item(
                TableName=DYNAMO_TABLE,
                Key={"request_id": {"S": request_id}},
                UpdateExpression="SET #u=:updated_at, #s=:status, #r=:result",
                ExpressionAttributeNames = {
                    "#u": "updated_at",
                    "#s": "status",
                    "#r": "result"
                },
                ExpressionAttributeValues=item,
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
