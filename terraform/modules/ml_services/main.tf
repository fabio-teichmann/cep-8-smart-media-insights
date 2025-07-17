locals {
  lambda_ingest_path = "${path.module}/../../../scripts/lambda_ingest"
}

# IAM for Lambda
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_lambda_permission" "allow_bucket_comprehend" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_to_comprehend_to_dynamo.arn
  principal     = "s3.amazonaws.com"
  source_arn    = var.s3_media_bucket_arn
}

resource "aws_s3_bucket_notification" "bucket_notification_text" {
  bucket = var.s3_media_bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_to_comprehend_to_dynamo.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/text/"
  }

  depends_on = [aws_lambda_permission.allow_bucket_comprehend]
}

resource "aws_lambda_function" "s3_to_comprehend_to_dynamo" {
  filename      = "${local.lambda_ingest_path}/lambda_comprehend.zip"
  function_name = "lambda_s3_to_comprehend_to_dynamodb"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_handler.lambda_handler"

  source_code_hash = filebase64sha256("${local.lambda_ingest_path}/lambda_ingest.zip")

  runtime     = "python3.12"
  timeout     = 10
  memory_size = 128

  vpc_config {
    subnet_ids         = var.vpc_private_subnets
    security_group_ids = [var.lambda_sg_id]
  }

  environment {
    variables = {
      "DYNAMO_TABLE" = var.dynamodb_status_table
      "LOGFIRE_TOKEN" = var.logfire_api_key
    }
  }
}

# resource "aws_lambda_event_source_mapping" "lambda_comprehend_trigger" {
#   event_source_arn = var.s3_media_bucket_arn #aws_kinesis_stream.ingest_stream.arn
#   function_name    = aws_lambda_function.s3_to_comprehend_to_dynamo.arn
#   enabled          = true

#   starting_position = "LATEST"
# }