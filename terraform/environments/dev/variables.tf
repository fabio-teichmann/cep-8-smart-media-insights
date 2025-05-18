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


variable "app_alb_port" {
    type = number

    validation {
        condition = var.app_alb_port >= 1024 && var.app_alb_port <= 49151
        error_message = "app port for ALB must be between 1,024 and 49,151"
    }
}