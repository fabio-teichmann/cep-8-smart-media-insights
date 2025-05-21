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
# variable "public_subnets" {
#     type = list(string)
# }

# variable "log_bucket" {
#     description = "id of S3 bucket for log storage"
#     type = string
# }

# variable "vpc_id" {
#     type = string
# }


variable "eks_namespace" {
  type    = string
  default = "kube-system"
}

variable "openid_connect_eks_arn" {
  type = string
}

variable "openid_connect_eks_url" {
  type = string
}