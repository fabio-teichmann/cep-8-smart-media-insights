resource "random_string" "bucket_suffix" {
  length  = 6
  upper   = false
  special = false
  numeric = true
}

resource "aws_s3_bucket" "media_bucket" {
    bucket = "media-bucket-${random_string.bucket_suffix.result}"
    force_destroy = true

    tags = {
        Environment = var.env 
        Terraform = true
    }
}

resource "aws_s3_bucket_lifecycle_configuration" "media_bucket_lifecycle" {
    bucket = aws_s3_bucket.media_bucket.id
    rule {
        id = "upload_data_purge"
        status = "Enabled"

        filter {
            prefix = "uploads/"
        }

        expiration {
          days = 30
        }
    }
}


# DynamoDB table ######################
resource "aws_dynamodb_table" "request_status_lookup" {
    name = "${var.plat_name}-request-status"
    billing_mode = "PROVISIONED"
    hash_key = "request_id"
    read_capacity  = 5
    write_capacity = 5

    attribute {
      name = "request_id"
      type = "S"
    }

    attribute {
        name = "status"
        type = "S"
    }

    attribute {
      name = "created_at"
      type = "S"
    }

    attribute {
      name = "processed_at"
      type = "S"
    }

    attribute {
        name = "result"
        type = "S"
    }

    # NOTE: deferred for now;
    # ttl {
    #     attribute_name = "expires_at"
    #     enabled = true
    # }

    global_secondary_index {
      name = "status-index"
      hash_key = "status"
      range_key = "created_at"
      read_capacity = 5
      write_capacity = 5
      projection_type = "ALL"
    }
    tags = {
        Environment = var.env
        Terraform = true
    }
}

# Kinesis Data Stream #################
resource "aws_kinesis_stream" "ingest_stream" {
    name = "${var.plat_name}-kinesis-ingest"
    shard_count = var.kinesis_shard_count

    shard_level_metrics = [
        "IncomingBytes",
        "OutgoingBytes",
    ]

    stream_mode_details {
      stream_mode = "PROVISIONED"
    }

    tags = {
        Name = "${var.plat_name}-kinesis-ingest"
        Environment = var.env
        Terraform = true
    }
}

# Lambda IAM
data "aws_iam_policy_document" "lambda_assume_role" {
    statement {
      effect = "Allow"
      principals {
        type = "Service"
        identifiers = ["lambda.amazonaws.com"]
      }
      actions = ["sts:AssumeRole"]
    }
}

resource "aws_iam_role" "iam_for_lambda" {
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_iam_policies" {
    statement {
      effect = "Allow"
      actions = [
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
      ]
      resources = [aws_dynamodb_table.request_status_lookup.arn]
    }

    statement {
      effect = "Allow"
      actions = [
        "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListStreams"
      ]
      resources = [aws_kinesis_stream.ingest_stream.arn]
    }

    statement {
      effect = "Allow"
      actions = [ 
        "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
      ]
      resources = ["*"]
    }
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.iam_for_lambda.id
  policy = data.aws_iam_policy_document.lambda_iam_policies.json
}


# Lambda (Kinesis -> Dynamo) 
data "archive_file" "lambda" {
    type = "zip"
    source_file = "../../scripts/lambda/kinesis-to-dynamo.py"
    output_path = "lambda_payload.zip"
}

resource "aws_lambda_function" "kinesis_to_dynamo" {
    filename = "lambda_payload.zip"
    function_name = "lambda_kinesis_to_dynamo"
    role = aws_iam_role.iam_for_lambda.arn 
    handler = "kinesis-to-dynamo.lambda_handler"

    source_code_hash = data.archive_file.lambda.output_base64sha256

    runtime = "python3.12"
    timeout = 10
    memory_size = 128

    vpc_config {
        subnet_ids         = var.vpc_private_subnets
        security_group_ids = [var.lambda_sg_id]
    }
}

resource "aws_lambda_event_source_mapping" "lambda_kinesis_trigger" {
    event_source_arn = aws_kinesis_stream.ingest_stream.arn
    function_name = aws_lambda_function.kinesis_to_dynamo.arn
    enabled = true

    starting_position = "LATEST"
}

