output "bastion_private_key" {
  value     = tls_private_key.bastion_key.private_key_pem
  sensitive = true
}

output "bastion_public_ip" {
  value = aws_instance.bastion_host.public_ip
}

output "bastion_sg" {
  value = aws_security_group.bastion_sg.id
}

output "bastion_id" {
  value = aws_instance.bastion_host.id
}

output "bastion_role_arn" {
  value = aws_iam_role.bastion_ssm_role.arn
}

output "bastion_role_name" {
  value = aws_iam_role.bastion_ssm_role.name
}
