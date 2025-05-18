module "vpc" {
    source = "../../modules/aws_vpc"

    env = var.env
    plat-name = var.plat-name
}

module "bastion_host" {
    source = "../../modules/bastion_host"

    user-ip = "" # TODO
    vpc_id = module.vpc.vpc_id

    bastion_ami_id = ""

    env = var.env
    plat-name = var.plat-name

    depends_on = [ module.vpc ]
}

module "alb" {
    source = "../../modules/aws_alb"

    env = var.env
    plat-name = var.plat-name

    public_subnets = module.vpc.vpc_public_subnets
    vpc_id = module.vpc.vpc_id

    log_bucket = "" # TODO

    depends_on = [ module.vpc ]
}

module "eks" {
    source = "../../modules/aws_eks"

    env = var.env
    plat-name = var.plat-name

    vpc_id = module.vpc.vpc_id
    vpc_private_subnets = module.vpc.vpc_private_subnets

    # TODO: remove ALB once replaced with automated creation
    # through EKS and automated kubectl delete through CI/CD
    app_alb_port = var.app_alb_port
    alb_security_group_id = module.alb.alb_sg_id
    bastion_sg_id = module.bastion_host.bastion_sg

    user-ip = "" # TODO

    depends_on = [ module.alb, module.vpc, module.bastion_host ]
}