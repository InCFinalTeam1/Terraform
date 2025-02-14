module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-${var.project_name}-${var.env}"
  cidr = var.vpc_cidr

  azs             = [for i in range(var.az_count) : "${var.region}${["a", "b", "c", "d"][i]}"]
  private_subnets = [for i in range(var.az_count) : var.pri-subnet[i]]
  public_subnets  = [for i in range(var.az_count) : var.pub-subnet[i]]

  enable_nat_gateway = true
  single_nat_gateway = true

  map_public_ip_on_launch = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    # "karpenter.sh/discovery" = "${var.eks_name}-${var.env}-test"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    # "karpenter.sh/discovery" = "${var.eks_name}-${var.env}-test"
  }

  tags = {
    Terraform = "true"
    Environment = var.env
  }
}