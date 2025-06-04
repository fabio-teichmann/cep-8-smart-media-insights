output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_private_subnets" {
  value = module.vpc.private_subnets
}

output "vpc_public_subnets" {
  value = module.vpc.public_subnets
}

output "lambda_sg_id" {
  value = aws_security_group.lambda_sg.id
}

output "vpc_endpoint_sg_id" {
    value = aws_security_group.vpc_enpoint_sg.id
}

output "vpc_private_route_table_ids" {
    value = module.vpc.private_route_table_ids
}