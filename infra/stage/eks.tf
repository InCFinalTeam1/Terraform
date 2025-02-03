module "eks-v1" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = "${var.eks_name}-${var.env}-v1"
  cluster_version = var.eks_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    system = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t3.medium", "t3.large", "c4.large", "c5.large"]
      capacity_type  = "ON_DEMAND"
    }
    general-purpose = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t3.micro", "t3.small", "t3.medium", "t3.large", "c4.large", "c5.large"]
      capacity_type  = "SPOT"
    }
  }

  tags = {
    Environment                                        = var.env
    Terraform                                          = "true"
#    "kubernetes.io/cluster/${module.eks.cluster_name}" = "shared"
  }
}

module "eks-v1_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.19" #ensure to update this to the latest/desired version

  cluster_name      = module.eks-v1.cluster_name
  cluster_endpoint  = module.eks-v1.cluster_endpoint
  cluster_version   = module.eks-v1.cluster_version
  oidc_provider_arn = module.eks-v1.oidc_provider_arn

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

# kubernetes_config-map 생성을 위해서 필요
provider "kubernetes" {
  host                   = module.eks-v1.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks-v1.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks-v1.cluster_name]
  }
}

resource "kubernetes_config_map" "kubernetes_env_vars" {
  metadata {
    name      = "kubernetes-env-vars"
    namespace = "kube-system"
  }

  data = {
    KUBERNETES_MASTER = module.eks-v1.cluster_endpoint
    ENV = var.env
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks-v1.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks-v1.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks-v1.cluster_name]
    }
  }
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks-v1.cluster_endpoint
}

output "eks_cluster_ca_cert" {
  value = module.eks-v1.cluster_certificate_authority_data
}

# # 삭제 시, provider "helm" 안에 참조하는 부분 모두 고정값으로 적어주고 terraform apply
# # Bastion Host의 Cluster-sg 제거!

# provider "kubernetes" {
#   host                   = "https://F87F96C41FF614791114BE1ADA4E4241.gr7.ap-northeast-2.eks.amazonaws.com"
#   cluster_ca_certificate = base64decode("LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJQkhpU2ZsWUdvWVV3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBeU1ETXdOakkxTlRCYUZ3MHpOVEF5TURFd05qTXdOVEJhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUURDM3pyWTVYeGlicnU4dS9pNUg3MnF0RTN0UVQwSnN0U21iSnZLYkFVSXNGSHVlWmNpT0xPK1R5QW4KR2NtSGE2Nk9NaVJBRjVGekpLZ2N2MTM2a0EyRURUY2pvb1lYa245Z2w5eXFtb1JyWEo2cVBvc2RUVi80TXZjbwpLWUJPZFplNjh3cGNSM0FTOGwwQndlVHV1Rk83Q3NzY2lac085YWdHUFVuOEFSTmdNa1JiR2ZqT1J4cG5jL2FECkplZ2pRSi82dnlaZ3o2enJockgwWjFpQjd5b0ttNncyYURULytUWExFVEQzRDBEZzhoNCtkZHdTY2VOYmoxeGEKd3RwcVVFU0tJSEFYNmU1dXM0Ky83WG1aeXBtOXh1Vk5WL3BDNENxWmlnanJneUJHbE10RXNtbWJHMWVLWEJKKwp3aEdWclpHcW9FWjM1WHhpZ2Z6TVVLUXdVRXlKQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJReGdBc1N1RHNSVk40Q1UvaGd0OEpOcUhKSVh6QVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQkNHd0o4Rzc4aQpIRWtLSjZiMzN0ekE5VXJFWEk2NlEzNTZrWjVDWEZ0Ylo2RTV5Um1LbWh3QzJBZTR4N1NlWDdDaVRRSFRFZDhOCkRRTTRnQVlkRUJ2T2J3WllxL3hJdlYrNmMrV1hqSEFxS3Z2UFZyUWJYdVhGT0p0SFJwNGRJclY1VXJzTFlwdnEKS3pUdVZLMmdQUmpTMXQ3c3pBMUpRY0R0VWpOQjBZQ2hNK1ZNQnhFc0NkZS9TNFB2dkRjaGtsajlBNWZXR1UvRApXN0NPSnZQd0IvNWdrN0pIZ1BnWGh2YWwydFptYUZBT0ppRSsxMTBLc3k5bFUwN1lod1lNSFczckltNlphcWdnClI2MEsxVTh1dm9LQUo1c1J5UXA5YUVRQnBwbGgxVHltRFR4Q3NmVm42NFpEcWxKZUd3NEg5c3Rpdy80QnJoU0wKYkp1bzhPZ05zY1hiCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K")
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args        = ["eks", "get-token", "--cluster-name", "eks-staging-v1"]
#   }
# }

# provider "helm" {
#   kubernetes {
#     host                   = "https://F87F96C41FF614791114BE1ADA4E4241.gr7.ap-northeast-2.eks.amazonaws.com"
#     cluster_ca_certificate = base64decode("LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJQkhpU2ZsWUdvWVV3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBeU1ETXdOakkxTlRCYUZ3MHpOVEF5TURFd05qTXdOVEJhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUURDM3pyWTVYeGlicnU4dS9pNUg3MnF0RTN0UVQwSnN0U21iSnZLYkFVSXNGSHVlWmNpT0xPK1R5QW4KR2NtSGE2Nk9NaVJBRjVGekpLZ2N2MTM2a0EyRURUY2pvb1lYa245Z2w5eXFtb1JyWEo2cVBvc2RUVi80TXZjbwpLWUJPZFplNjh3cGNSM0FTOGwwQndlVHV1Rk83Q3NzY2lac085YWdHUFVuOEFSTmdNa1JiR2ZqT1J4cG5jL2FECkplZ2pRSi82dnlaZ3o2enJockgwWjFpQjd5b0ttNncyYURULytUWExFVEQzRDBEZzhoNCtkZHdTY2VOYmoxeGEKd3RwcVVFU0tJSEFYNmU1dXM0Ky83WG1aeXBtOXh1Vk5WL3BDNENxWmlnanJneUJHbE10RXNtbWJHMWVLWEJKKwp3aEdWclpHcW9FWjM1WHhpZ2Z6TVVLUXdVRXlKQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJReGdBc1N1RHNSVk40Q1UvaGd0OEpOcUhKSVh6QVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQkNHd0o4Rzc4aQpIRWtLSjZiMzN0ekE5VXJFWEk2NlEzNTZrWjVDWEZ0Ylo2RTV5Um1LbWh3QzJBZTR4N1NlWDdDaVRRSFRFZDhOCkRRTTRnQVlkRUJ2T2J3WllxL3hJdlYrNmMrV1hqSEFxS3Z2UFZyUWJYdVhGT0p0SFJwNGRJclY1VXJzTFlwdnEKS3pUdVZLMmdQUmpTMXQ3c3pBMUpRY0R0VWpOQjBZQ2hNK1ZNQnhFc0NkZS9TNFB2dkRjaGtsajlBNWZXR1UvRApXN0NPSnZQd0IvNWdrN0pIZ1BnWGh2YWwydFptYUZBT0ppRSsxMTBLc3k5bFUwN1lod1lNSFczckltNlphcWdnClI2MEsxVTh1dm9LQUo1c1J5UXA5YUVRQnBwbGgxVHltRFR4Q3NmVm42NFpEcWxKZUd3NEg5c3Rpdy80QnJoU0wKYkp1bzhPZ05zY1hiCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K")
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args        = ["eks", "get-token", "--cluster-name", "eks-staging-v1"]
#     }
#   }
# }