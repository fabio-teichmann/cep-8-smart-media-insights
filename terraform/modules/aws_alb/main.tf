resource "aws_lb" "alb" {
    name = "${var.plat-name}-alb"
    internal = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.lb_sg.id]
    subnets = [for subnet in var.public_subnets : subnet.id]

    enable_deletion_protection = false 

    access_logs {
        bucket = var.log_bucket
        enabled = true
        prefix = "logs/${var.plat-name}-alb"
    }

    tags = {
        Environment = var.env
        Terraform = true
    }
}

resource "aws_security_group" "alb_security_group" {
    name = "${var.plat-name}-alb-sg"
    vpc_id = var.vpc_id

    tags = {
        Environment = var.env
        Terraform = true
    }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.alb_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # all ports
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
    security_group_id = aws_security_group.alb_security_group.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 80
    ip_protocol = "tcp"
    to_port = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_ipv4" {
    security_group_id = aws_security_group.alb_security_group.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 443
    ip_protocol = "tcp"
    to_port = 443
}
