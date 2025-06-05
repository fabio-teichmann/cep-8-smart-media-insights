output "vpc_id" {
  value = module.vpc.vpc_id
}

output "bastion_id" {
    value = module.bastion_host.bastion_id
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "eks_irsa_role_arn" {
  value = module.eks.irsa_role_arn
}

output "eks_svc_acc_name" {
  value = module.eks.eks_svc_acc_name
}

# Ingestion Pipeline
output "s3_media_bucket" {
  value = module.ingestion.s3_media_bucket
}

output "dynamodb_status_table" {
  value = module.ingestion.dynamodb_status_table
}

output "kinesis_stream_name" {
  value = module.ingestion.kinesis_stream_name
}

# ML Service Pipeline
