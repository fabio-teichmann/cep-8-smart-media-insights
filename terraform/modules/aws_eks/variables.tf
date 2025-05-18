# general ######################
variable "env" {
    type = string
    default = "dev"

    validation {
        condition = contains(["dev", "stage", "prod"], var.env)
        error_message = "value"
    }
}

variable "plat-name" {
    type = string

    validation {
        condition = length(var.plat-name) != 0
        error_message = "name must be set"
    }
    validation {
        condition = !can(regex("_", var.plat-name))
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

variable "app_alb_port" {
    type = number

    validation {
        condition = var.app_alb_port >= 1024 && var.app_alb_port <= 49151
        error_message = "app port for ALB must be between 1,024 and 49,151"
    }
}

variable "alb_security_group_id" {
    description = "security group id of the ALB module"
    type = string
}

variable "bastion_sg_id" {
    type = string
}

# temporary #################
variable "user-ip" {
    type = string
}