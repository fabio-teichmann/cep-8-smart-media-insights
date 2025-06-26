data "aws_availability_zones" "available" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = "${var.plat_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform   = true
    Environment = var.env
  }
}

# Security Groups 
# -- for Endpoints
resource "aws_security_group" "vpc_enpoint_sg" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name        = "${var.plat_name}-vpc-endpoint-sg"
    Environment = var.env
    Terraform   = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  for_each = toset(module.vpc.private_subnets_cidr_blocks)

  security_group_id = aws_security_group.vpc_enpoint_sg.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  for_each = toset(module.vpc.public_subnets_cidr_blocks)

  security_group_id = aws_security_group.vpc_enpoint_sg.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "all_out" {
  security_group_id = aws_security_group.vpc_enpoint_sg.id
  ip_protocol       = "-1"
#   from_port         = 0
#   to_port           = 0
  cidr_ipv4         = "0.0.0.0/0"
}

# -- for Lambdas
resource "aws_security_group" "lambda_sg" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name        = "${var.plat_name}-vpc-endpoint-sg"
    Environment = var.env
    Terraform   = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_lambda" {
  for_each = toset(module.vpc.private_subnets_cidr_blocks)

  security_group_id = aws_security_group.lambda_sg.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}


resource "aws_vpc_security_group_egress_rule" "all_out_lambda" {
  security_group_id = aws_security_group.lambda_sg.id
  ip_protocol       = "-1"
#   from_port         = 0
#   to_port           = 0
  cidr_ipv4         = "0.0.0.0/0"
}



# # VPC Endpoint(s) ############
# resource "aws_vpc_endpoint" "s3" {
#   vpc_id          = module.vpc.vpc_id
#   service_name    = "com.amazonaws.${var.region}.s3"
#   route_table_ids = module.vpc.private_route_table_ids
# }

# resource "aws_vpc_endpoint" "dynamo_db" {
#   vpc_id          = module.vpc.vpc_id
#   service_name    = "com.amazonaws.${var.region}.dynamodb"
#   route_table_ids = module.vpc.private_route_table_ids
# }

# resource "aws_vpc_endpoint" "kinesis_stream" {
#   vpc_id            = module.vpc.vpc_id
#   service_name      = "com.amazonaws.${var.region}.kinesis"
#   vpc_endpoint_type = "Interface"

#   private_dns_enabled = true

#   subnet_ids         = module.vpc.private_subnets 
#   security_group_ids = [aws_security_group.vpc_enpoint_sg.id]
# }