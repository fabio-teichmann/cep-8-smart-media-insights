# resource "aws_lb" "alb" {
#     name = "${var.plat_name}-alb"
#     internal = false
#     load_balancer_type = "application"
#     security_groups    = [aws_security_group.lb_sg.id]
#     subnets = [for subnet in var.public_subnets : subnet.id]

#     enable_deletion_protection = false 

#     access_logs {
#         bucket = var.log_bucket
#         enabled = true
#         prefix = "logs/${var.plat_name}-alb"
#     }

#     tags = {
#         Environment = var.env
#         Terraform = true
#     }
# }

# resource "aws_security_group" "alb_security_group" {
#     name = "${var.plat_name}-alb-sg"
#     vpc_id = var.vpc_id

#     tags = {
#         Environment = var.env
#         Terraform = true
#     }
# }

# resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
#   security_group_id = aws_security_group.alb_security_group.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1" # all ports
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
#     security_group_id = aws_security_group.alb_security_group.id
#     cidr_ipv4 = "0.0.0.0/0"
#     from_port = 80
#     ip_protocol = "tcp"
#     to_port = 80
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_https_ipv4" {
#     security_group_id = aws_security_group.alb_security_group.id
#     cidr_ipv4 = "0.0.0.0/0"
#     from_port = 443
#     ip_protocol = "tcp"
#     to_port = 443
# }




# IRSA (IAM Roles for Service Accounts) for AWS Load Balancer Controller ###############
data "aws_iam_policy_document" "alb_controller_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.openid_connect_eks_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(var.openid_connect_eks_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.eks_namespace}:aws-load-balancer-controller"]
    }
  }
}

resource "aws_iam_role" "alb_controller" {
  name               = "alb-controller-role"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume_role.json
}

resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancerController"
}
