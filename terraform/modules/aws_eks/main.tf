# IAM + Routing for EKS ########
resource "aws_security_group_rule" "bastion_to_nodes" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = var.bastion_sg_id
  security_group_id        = module.eks.cluster_security_group_id
}

resource "aws_security_group_rule" "bastion_to_nodes_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = var.bastion_sg_id
  security_group_id        = module.eks.cluster_security_group_id
}

# IRSA for EKS ##############
data "aws_eks_cluster" "smart-media" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.smart-media.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "eks_irsa_policies" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.eks.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.app_namespace}:${var.eks_svc_acc_name}"]
    }
  }
}

resource "aws_iam_role" "irsa_role" {
  name               = "${var.plat_name}-eks-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.eks_irsa_policies.json
}

data "aws_iam_policy_document" "irsa_policies" {
  statement {
    effect = "Allow"
    actions = [
      "kinesis:PutRecord",
      "kinesis:PutRecords",
      "s3:PutObject",
      "dynamodb:GetItem",
      "dynamodb:GetItems"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "eks_irsa_policy" {
  name   = "${var.plat_name}-eks-irsa-policies"
  policy = data.aws_iam_policy_document.irsa_policies.json
}

resource "aws_iam_role_policy_attachment" "attach_irsa_policies" {
  role       = aws_iam_role.irsa_role.name
  policy_arn = aws_iam_policy.eks_irsa_policy.arn
}

# EKS Cluster ########################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0" # Latest stable as of May 2025

  cluster_name    = "${var.plat_name}-eks"
  cluster_version = "1.32"
  subnet_ids      = var.vpc_private_subnets
  vpc_id          = var.vpc_id

  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"

      update_launch_template_default_version = false
      # iam_role_attach_cni_policy = false 
    }
  }
  # enabled only for development to troubleshoot with `kubectl` from local.
  # will be disabled once bastion is set up
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["${var.user_ip}/32", "10.0.101.0/24", "10.0.102.0/24"] # restrict in production

  cluster_endpoint_private_access = true

  tags = {
    Environment = var.env
    Terraform   = "true"
  }
}

# resource "aws_security_group_rule" "allow_alb_to_eks" {
#   type              = "ingress"
#   from_port         = var.app_alb_port
#   to_port           = var.app_alb_port
#   protocol          = "tcp"
#   security_group_id = module.eks.node_security_group_id
#   source_security_group_id = var.alb_security_group_id
# }
