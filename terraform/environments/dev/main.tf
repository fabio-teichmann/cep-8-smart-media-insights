terraform {
  backend "s3" {
    bucket         = ""
    key            = ""
    region         = ""
    dynamodb_table = ""
    encrypt        = ""
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.24.0"
    }
  }
  required_version = ">= 1.3.0"
}


module "vpc" {
  source = "../../modules/aws_vpc"

  env       = var.env
  plat_name = var.plat_name
}

module "bastion_host" {
  source = "../../modules/bastion_host"

  user_ip = var.user_ip
  vpc_id  = module.vpc.vpc_id

  bastion_ami_id = var.bastion_ami_id
  vpc_public_subnets = module.vpc.vpc_public_subnets

  env       = var.env
  plat_name = var.plat_name
  eks_cluster_name = module.eks.cluster_name
  eks_cluster_arn = module.eks.cluster_arn

  s3_static_bucket = var.s3_static_bucket
}

module "eks" {
  source = "../../modules/aws_eks"

  env       = var.env
  plat_name = var.plat_name

  vpc_id              = module.vpc.vpc_id
  vpc_private_subnets = module.vpc.vpc_private_subnets

  eks_svc_acc_name = var.eks_svc_acc_name

  bastion_sg_id = module.bastion_host.bastion_sg

  user_ip = var.user_ip
}

module "ingestion" {
  source = "../../modules/ingestion"

  plat_name = var.plat_name
  env       = var.env

  vpc_private_subnets = module.vpc.vpc_private_subnets
  lambda_sg_id        = module.vpc.lambda_sg_id
  logfire_api_key = var.logfire_api_key

  depends_on = [module.vpc]
}

module "vpc_endpoints" {
    source = "../../modules/vpc_endpoints"

    vpc_id = module.vpc.vpc_id
    vpc_private_subnets = module.vpc.vpc_private_subnets
    vpc_public_subnets = module.vpc.vpc_public_subnets
    vpc_endpoint_sg_id = module.vpc.vpc_endpoint_sg_id
    vpc_private_route_table_ids = module.vpc.vpc_private_route_table_ids

    depends_on = [ module.ingestion ]
}

# render scripts
module "bootstrap" {
  source = "../../modules/bootstraps"

  vpc_id = module.vpc.vpc_id
  eks_cluster_name = module.eks.cluster_name
  env = var.env

  s3_static_bucket = var.s3_static_bucket

  logfire_url = var.logfire_url
  logfire_project_name = var.logfire_project_name
  logfire_api_key = var.logfire_api_key
  dynamodb_status_table = module.ingestion.dynamodb_status_table
  s3_media_bucket = module.ingestion.s3_media_bucket
  kinesis_stream_name = module.ingestion.kinesis_stream_name

  dockerhub_user = var.dockerhub_user

  svc_acc_name = module.eks.eks_svc_acc_name
  svc_acc_annot = module.eks.irsa_role_arn

  depends_on = [ module.vpc, module.eks, module.ingestion ]
}


module "ml_services" {
  source = "../../modules/ml_services"

  vpc_private_subnets = module.vpc.vpc_private_subnets
  lambda_sg_id        = module.vpc.lambda_sg_id

  s3_media_bucket_id = module.ingestion.s3_media_bucket
  s3_media_bucket_arn = module.ingestion.s3_media_bucket_arn
  dynamodb_status_table = module.ingestion.dynamodb_status_table
  dynamo_status_table_arn = module.ingestion.dynamo_status_table_arn

  logfire_api_key = var.logfire_api_key

}
