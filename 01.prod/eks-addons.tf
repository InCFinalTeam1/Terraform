module "eks-prod_blueprints_addons" {
  depends_on = [module.eks-prod, time_sleep.wait_30s]
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.19" #ensure to update this to the latest/desired version

  cluster_name      = module.eks-prod.cluster_name
  cluster_endpoint  = module.eks-prod.cluster_endpoint
  cluster_version   = module.eks-prod.cluster_version
  oidc_provider_arn = module.eks-prod.oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
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

  enable_external_secrets                      = true
  enable_secrets_store_csi_driver              = true
  enable_secrets_store_csi_driver_provider_aws = true
  enable_aws_load_balancer_controller          = true
  enable_kube_prometheus_stack                 = true
  enable_metrics_server                        = true
  enable_external_dns                          = true
  external_dns = {
    route53_zone_arns = [var.route53_zone_arn]
  }
  enable_argocd                                = true
  enable_karpenter                             = true
  karpenter = {
    helm_config = "0.37.0"
  }
  karpenter_enable_spot_termination            = true
  enable_aws_cloudwatch_metrics                = true

  tags = {
    Environment = var.env
  }
}

# kubernetes_config-map 생성을 위해서 필요
provider "kubernetes" {
  host                   = module.eks-prod.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks-prod.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks-prod.cluster_name]
  }
}

resource "kubernetes_config_map" "kubernetes_env_vars" {
  depends_on = [module.eks-prod, module.eks-prod_blueprints_addons]

  metadata {
    name      = "kubernetes-env-vars"
    namespace = "kube-system"
  }

  data = {
    KUBERNETES_MASTER = module.eks-prod.cluster_endpoint
    ENV = var.env
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks-prod.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks-prod.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks-prod.cluster_name]
    }
  }
}

# 클러스터 준비 대기용 리소스
resource "time_sleep" "wait_30s" {
  depends_on      = [module.eks-prod]
  create_duration = "30s"
}