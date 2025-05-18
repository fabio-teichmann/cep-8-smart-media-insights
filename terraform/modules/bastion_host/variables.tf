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

# module specific ###########
variable "bastion_ami_id" {
    type = string
}

variable "vpc_id" {
    type = string
}

# temporary #################
variable "user-ip" {
    type = string
}