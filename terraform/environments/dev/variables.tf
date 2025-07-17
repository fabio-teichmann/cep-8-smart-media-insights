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

variable "eks_svc_acc_name" {
  type = string
}

variable "user_ip" {
  type = string
}

variable "bastion_ami_id" {
  type    = string
  default = "ami-0953476d60561c955"
}

variable "s3_static_bucket" {
  type = string
}

# variable "app_alb_port" {
#     type = number

#     validation {
#         condition = var.app_alb_port >= 1024 && var.app_alb_port <= 49151
#         error_message = "app port for ALB must be between 1,024 and 49,151"
#     }
# }

# for script rendering
variable "dockerhub_user" { type = string }
variable "logfire_url" { type = string }
variable "logfire_project_name" { type = string }
variable "logfire_api_key" { 
    type = string 
    sensitive = true
}