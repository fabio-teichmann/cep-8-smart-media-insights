variable "region" {
    type = string
    default = "us-east-1"
}
variable "vpc_id" {
    type = string 
}
variable "vpc_private_route_table_ids" {
    type = list(string)
}

variable "vpc_private_subnets" {
    type = list(string)
}

variable "vpc_endpoint_sg_id" {
    type = string
}