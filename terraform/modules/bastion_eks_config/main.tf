# aws-auth signed transactions with EKS
data "template_file" "aws_auth_configmap" {
  template = file("${path.module}/templates/aws-auth.yaml.tpl")

  vars = {
    role_arn = var.bastion_role_arn #aws_iam_role.bastion_ssm.arn
    role_name = var.bastion_role_name #aws_iam_role.bastion_ssm_role.name
  }
}

resource "null_resource" "update_aws_auth" {
  provisioner "local-exec" {
    command = <<EOT
      echo '${data.template_file.aws_auth_configmap.rendered}' > aws-auth.yaml
      aws eks update-kubeconfig --name ${var.eks_cluster_name} --region ${var.region}
      kubectl apply -f aws-auth.yaml
    EOT
  }

#   depends_on = [
#     aws_iam_role.bastion_ssm_role
#   ]
}