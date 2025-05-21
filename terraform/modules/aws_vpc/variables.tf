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

# module specific ##############
variable "region" {
  type    = string
  default = "us-east-1"
}