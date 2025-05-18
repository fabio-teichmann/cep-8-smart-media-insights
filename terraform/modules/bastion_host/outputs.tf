output "bastion_private_key" {
  value     = tls_private_key.bastion_key.private_key_pem
  sensitive = true
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_sg" {
    value = aws_security_group.bastion_sg.id
}
