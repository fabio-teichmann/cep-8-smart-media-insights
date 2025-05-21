module "vpc" {
    source = "../../modules/aws_vpc"

    env = var.env
    plat_name = var.plat_name
}

module "bastion_host" {
    source = "../../modules/bastion_host"

    user_ip = var.user_ip
    vpc_id = module.vpc.vpc_id

    bastion_ami_id = var.bastion_ami_id

    env = var.env
    plat_name = var.plat_name

    depends_on = [ module.vpc ]
}

module "eks" {
    source = "../../modules/aws_eks"

    env = var.env
    plat_name = var.plat_name

    vpc_id = module.vpc.vpc_id
    vpc_private_subnets = module.vpc.vpc_private_subnets

    eks_svc_acc_name = var.eks_svc_acc_name
    # TODO: remove ALB once replaced with automated creation
    # through EKS and automated kubectl delete through CI/CD
    # app_alb_port = var.app_alb_port
    # alb_security_group_id = module.alb.alb_sg_id
    bastion_sg_id = module.bastion_host.bastion_sg

    user_ip = var.user_ip

    depends_on = [ module.vpc, module.bastion_host ]
}

module "alb" {
    source = "../../modules/aws_alb"

    plat_name = var.plat_name
    env = var.env

    openid_connect_eks_arn = module.eks.openid_connect_eks_arn
    openid_connect_eks_url = module.eks.openid_connect_eks_url

    depends_on = [ module.eks ]
}
