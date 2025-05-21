import os
import boto3
import json
import base64
import logfire
from botocore.exceptions import ClientError

logfire.configure()

dynamo_client = boto3.client("dynamodb")
DYNAMO_TABLE = os.getenv("DYNAMO_TABLE")


def lambda_handler(event, context):
    for record in event["Records"]:
        try:
            payload = base64.b64decode(record["kinesis"]["data"]).decode("utf-8")
            media_meta = json.loads(payload)
            logfire.info("Decoded metadata", extra=media_meta)

            item = {
                "request_id": {"S": media_meta["request_id"]},
                "created_at": {"S": media_meta["created_at"]},
                "status": {"S": media_meta["status"]},
                "media_type": {"S": media_meta["media_type"]},
            }

            response = dynamo_client.put_item(
                TableName=DYNAMO_TABLE,
                Item=item,
            )
            logfire.info("DynamoDB insert success", extra=response)

        except ClientError as e:
            logfire.error(f"Dynamo client error: {e}")
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
