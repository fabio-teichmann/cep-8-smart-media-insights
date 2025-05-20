output "eks_subnet_cidr_blocks" {
    value = module.eks.eks_subnet_cidr_blocks
}

output "openid_connect_eks_arn" {
    value = data.aws_iam_openid_connect_provider.eks.arn 
}

output "openid_connect_eks_url" {
    value = data.aws_iam_openid_connect_provider.eks.url
}