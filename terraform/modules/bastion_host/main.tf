resource "aws_security_group" "bastion_sg" {
  vpc_id = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ingress" {
  security_group_id = aws_security_group.bastion_sg.id
  description       = "allow SSH"
  ip_protocol       = "tcp"

  from_port = 22
  to_port   = 22
  cidr_ipv4 = "${var.user_ip}/32"
}

resource "aws_vpc_security_group_egress_rule" "bastion_egress" {
  security_group_id = aws_security_group.bastion_sg.id
  ip_protocol       = "-1"
#   from_port         = 0
#   to_port           = 0
  cidr_ipv4         = "0.0.0.0/0"
}

# TODO:
# Consider replacing this by a locally generated key-pair or AWS SSH agent
resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "bastion_key_pair" {
  public_key = tls_private_key.bastion_key.public_key_openssh
}

# IAM Profile ########
resource "aws_iam_role" "bastion_ssm_role" {
  name = "${var.plat_name}-bastion-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_ssm_policy" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion_ssm_profile" {
  name = "${var.plat_name}-bastion-ssm-profile"
  role = aws_iam_role.bastion_ssm_role.name
}


resource "aws_instance" "bastion_host" {
  ami                         = var.bastion_ami_id
  instance_type               = "t2.small"
  subnet_id                   = var.vpc_public_subnets[0]
  associate_public_ip_address = true

  key_name               = aws_key_pair.bastion_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  iam_instance_profile = aws_iam_instance_profile.bastion_ssm_profile.name

  tags = {
    Environment = var.env
    Terraform   = true
    Name        = "${var.plat_name}-bastion-host"
  }

  # for later when EKS API endpoint is moved to private only
  user_data = file("${path.module}/../../../scripts/bootstrap/bastion-startup.sh")

}

