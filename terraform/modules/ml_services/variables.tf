variable "vpc_private_subnets" {
  type = list(string)
}

variable "lambda_sg_id" {
  type = string
}

variable "logfire_api_key" {
  type = string
  sensitive = true
}

variable "s3_media_bucket_arn" {
    type = string
}

variable "s3_media_bucket_id" {
    type = string
}

variable "dynamodb_status_table" {
    type = string
}

variable "dynamo_status_table_arn" {
  type = string
}