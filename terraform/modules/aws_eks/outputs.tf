# Needed for self-hosted GHA runner
# NOTE: invalid module attribute; maybe `cluster_service_cidr` ?
# output "eks_subnet_cidr_blocks" {
#   value = module.eks.eks_subnet_cidr_blocks
# }

output "openid_connect_eks_arn" {
  value = data.aws_iam_openid_connect_provider.eks.arn
}

output "openid_connect_eks_url" {
  value = data.aws_iam_openid_connect_provider.eks.url
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "irsa_role_arn" {
  value = aws_iam_role.irsa_role.arn
}

output "eks_svc_acc_name" {
  value = var.eks_svc_acc_name
}