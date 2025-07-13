data "aws_caller_identity" "current" {}

locals {
  eks_alb_controller_rendered = templatefile("${path.module}/../../../scripts/bootstrap/eks-alb-controller.sh", {
    CLUSTER_NAME = var.eks_cluster_name,
    AWS_REGION = var.region,
    AWS_ACCOUNT_ID = data.aws_caller_identity.current.account_id,
    VPC_ID = var.vpc_id
  })

  app_deploy_script_rendered = templatefile("${path.module}/../../../scripts/bootstrap/helm-deploy-eks.sh", {
    CLUSTER_NAME = var.eks_cluster_name,
    AWS_REGION = var.region,
    DOCKERHUB_USER = var.dockerhub_user,

    LOGFIRE_URL = var.logfire_url,
    LOGFIRE_PROJECT_NAME = var.logfire_project_name,
    LOGFIRE_API_KEY = var.logfire_api_key,
    DYNAMO_TABLE = var.dynamodb_status_table,
    KDS_STREAM_NAME = var.kinesis_stream_name,
    S3_MEDIA_BUCKET = var.s3_media_bucket,

    SVC_ACC_NAME = var.svc_acc_name,
    SVC_ACC_ANNOT = var.svc_acc_annot
  })

  cloud_formation_stack_rendered = templatefile("${path.module}/../../../scripts/bootstrap/cloudformation-cleanup.sh", {
    AWS_REGION = var.region,
    CLUSTER_NAME= var.eks_cluster_name,
    NAMESPACE="kube-system",
    SERVICE_ACCOUNT_NAME="aws-load-balancer-controller"
  })
}

resource "aws_s3_object" "rendered_script" {
  bucket = var.s3_static_bucket
  key    = "scripts/bootstrap/eks-alb-controller.sh"
  content = local.eks_alb_controller_rendered
  content_type = "text/x-shellscript"

  tags = {
    Name        = "ALB Controller script"
    Environment = var.env
  }
}

resource "aws_s3_object" "rendered_script_deploy" {
    bucket = var.s3_static_bucket
    key = "scripts/bootstrap/helm-deploy-eks.sh"
    content = local.app_deploy_script_rendered
    content_type = "text/x-shellscript"

    tags = {
        Name = "Helm deploy charts script"
        Environment = var.env
    }
}

resource "aws_s3_object" "rendered_script_cloud_formation" {
    bucket = var.s3_static_bucket
    key = "scripts/bootstrap/cloudformation-cleanup.sh"
    content = local.cloud_formation_stack_rendered
    content_type = "text/x-shellscript"

    tags = {
        Name = "Cleanup CloudFormation Stack script"
        Environment = var.env
    }
}