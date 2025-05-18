output "vpc_id" {
    value = module.vpc.vpc_id
}

output "vpc_private_subnets" {
    value = module.vpc.vpc_private_subnets
}

output "vpc_public_subnets" {
    value = module.vpc.public_subnets
}