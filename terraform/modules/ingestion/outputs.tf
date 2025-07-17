output "s3_media_bucket" {
  value = aws_s3_bucket.media_bucket.id
}

output "s3_media_bucket_arn" {
  value = aws_s3_bucket.media_bucket.arn
}

output "dynamodb_status_table" {
  value = aws_dynamodb_table.request_status_lookup.id
}

output "kinesis_stream_name" {
  value = aws_kinesis_stream.ingest_stream.name
}