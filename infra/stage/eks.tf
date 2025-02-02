module "eks-dev1" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = "${var.eks_name}-${var.env}-dev1"
  cluster_version = var.eks_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    general = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t3.xlarge"]
      capacity_type  = "ON_DEMAND"
    }
  }

  tags = {
    Environment                                        = var.env
    Terraform                                          = "true"
#    "kubernetes.io/cluster/${module.eks.cluster_name}" = "shared"
  }
}

module "eks-dev1_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.19" #ensure to update this to the latest/desired version

  cluster_name      = module.eks-dev1.cluster_name
  cluster_endpoint  = module.eks-dev1.cluster_endpoint
  cluster_version   = module.eks-dev1.cluster_version
  oidc_provider_arn = module.eks-dev1.oidc_provider_arn

  eks_addons = {
    # aws-ebs-csi-driver = {
    #   most_recent = true
    # }
    aws-efs-csi-driver = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  enable_aws_load_balancer_controller    = true
#  enable_cluster_proportional_autoscaler = true
#  enable_karpenter                       = true
  enable_metrics_server                  = true
#  enable_external_dns                    = true
#  enable_cert_manager                    = true

  tags = {
    Environment = var.env
  }
}

provider "kubernetes" {
  host                   = module.eks-dev1.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks-dev1.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks-dev1.cluster_name]
  }
}

resource "kubernetes_config_map" "kubernetes_env_vars" {
  metadata {
    name      = "kubernetes-env-vars"
    namespace = "kube-system"
  }

  data = {
    KUBERNETES_MASTER = module.eks-dev1.cluster_endpoint
    ENV = var.env
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks-dev1.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks-dev1.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks-dev1.cluster_name]
    }
  }
}