# VPC Endpoint(s) ############
resource "aws_vpc_endpoint" "s3" {
  vpc_id          = var.vpc_id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = var.vpc_private_route_table_ids
}

resource "aws_vpc_endpoint" "dynamo_db" {
  vpc_id          = var.vpc_id
  service_name    = "com.amazonaws.${var.region}.dynamodb"
  route_table_ids = var.vpc_private_route_table_ids
}

resource "aws_vpc_endpoint" "kinesis_stream" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.kinesis-streams"
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  subnet_ids         = var.vpc_private_subnets 
  security_group_ids = [var.vpc_endpoint_sg_id]
}

resource "aws_vpc_endpoint" "eks" {
  vpc_id = var.vpc_id
  service_name = "com.amazonaws.${var.region}.eks"
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  subnet_ids         = var.vpc_private_subnets 
  security_group_ids = [var.vpc_endpoint_sg_id]
}