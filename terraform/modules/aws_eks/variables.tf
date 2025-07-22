# general ######################
variable "env" {
  type    = string
  default = "dev"

  validation {
    condition     = contains(["dev", "stage", "prod"], var.env)
    error_message = "value"
  }
}

variable "plat_name" {
  type = string

  validation {
    condition     = length(var.plat_name) != 0
    error_message = "name must be set"
  }
  validation {
    condition     = !can(regex("_", var.plat_name))
    error_message = "name must not contain underscores `_`"
  }
}

# module specific ######################
variable "vpc_id" {
  description = "VPC that EKS runs on"
}

variable "vpc_private_subnets" {
  type = list(string)
}

variable "bastion_sg_id" {
  type = string
}

# temporary #################
variable "user_ip" {
  type = string
}

variable "app_namespace" {
  type    = string
  default = "default"
}

variable "eks_svc_acc_name" {
  type = string
}