variable "region" {
  type = string 
  default = "us-east-1"
}

variable "bastion_role_arn" {
    type = string 
}

variable "bastion_role_name" {
    type = string
}

variable "eks_cluster_name" {
    type = string
}