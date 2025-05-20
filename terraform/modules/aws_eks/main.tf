# EKS Cluster ########################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"  # Latest stable as of May 2025

  cluster_name    = "${var.plat-name}-eks"
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
    }
  }

    # enabled only for development to troubleshoot with `kubectl` from local.
    # will be disabled once bastion is set up
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["${var.user-ip}/36"] # restrict in production

  cluster_endpoint_private_access = true

  tags = {
    Environment = var.env
    Terraform   = "true"
  }
}

resource "aws_security_group_rule" "allow_alb_to_eks" {
  type              = "ingress"
  from_port         = var.app_alb_port
  to_port           = var.app_alb_port
  protocol          = "tcp"
  security_group_id = module.eks.node_security_group_id
  source_security_group_id = var.alb_security_group_id
}

resource "aws_security_group_rule" "bastion_to_nodes" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = var.bastion_sg_id
  security_group_id        = module.eks.node_security_group_id
}

data "aws_eks_cluster" "smart-media" {
  name = module.eks.cluster_name
  depends_on = [ module.eks ]
}

data "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.webshop.identity[0].oidc[0].issuer
}
