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
  # TODO: remove ALB once replaced with automated creation
  # through EKS and automated kubectl delete through CI/CD
  # app_alb_port = var.app_alb_port
  # alb_security_group_id = module.alb.alb_sg_id
  bastion_sg_id = module.bastion_host.bastion_sg

  user_ip = var.user_ip

#   depends_on = [module.vpc, module.bastion_host]
}

# module "alb" {
#   source = "../../modules/aws_alb"

#   plat_name = var.plat_name
#   env       = var.env

#   openid_connect_eks_arn = module.eks.openid_connect_eks_arn
#   openid_connect_eks_url = module.eks.openid_connect_eks_url

#   depends_on = [module.eks]
# }



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
  logfire_api_key = var.logfire_api_key

}


# module "bastion_eks_config" {
#   source = "../../modules/bastion_eks_config"

#   eks_cluster_name = module.eks.cluster_name
#   bastion_role_arn = module.bastion_host.bastion_role_arn
#   bastion_role_name = module.bastion_host.bastion_role_name

#   depends_on = [ module.bastion_host, module.eks ]
# }

# # aws-auth signed transactions with EKS
# data "template_file" "aws_auth_configmap" {
#   template = file("${path.module}/templates/aws-auth.yaml.tpl")

#   vars = {
#     role_arn = var.bastion_role_arn #aws_iam_role.bastion_ssm.arn
#     role_name = var.bastion_role_name #aws_iam_role.bastion_ssm_role.name
#   }
# }

# resource "null_resource" "update_aws_auth" {
#   provisioner "local-exec" {
#     command = <<EOT
#       echo '${data.template_file.aws_auth_configmap.rendered}' > aws-auth.yaml
#       aws eks update-kubeconfig --name ${var.eks_cluster_name} --region ${var.region}
#       kubectl apply -f aws-auth.yaml
#     EOT
#   }

# #   depends_on = [
# #     aws_iam_role.bastion_ssm_role
# #   ]
# }

# resource "terraform_data" "patch_eks_aws_auth" {
#   provisioner "loval-exec" {
#     when = apply
#     command = <<EOT
#       echo 
#     EOT
#   }
# }