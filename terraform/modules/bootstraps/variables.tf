variable "env" { type = string }
variable "eks_cluster_name" { type = string }
variable "region" {
    type = string 
    default = "us-east-1"
}
variable "vpc_id" { type = string }
variable "s3_static_bucket" { type = string }
variable "dockerhub_user" { type = string }

variable "logfire_url" { type = string }
variable "logfire_project_name" { type = string }
variable "logfire_api_key" { 
    type = string 
    sensitive = true
}
variable "dynamodb_status_table" { type = string }
variable "s3_media_bucket" { type = string }
variable "kinesis_stream_name" { type = string }

variable "svc_acc_name" { type = string }
variable "svc_acc_annot" { type = string }