output "vpc_id" {
    value = module.vpc.vpc_id
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