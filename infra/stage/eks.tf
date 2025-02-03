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
#   enable_cluster_proportional_autoscaler = true
  enable_karpenter                       = true
  enable_metrics_server                  = true
  enable_external_dns                    = true
  enable_cert_manager                    = true

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
#   host                   = "https://D37F243D1CECB34ADD870D73574EB745.gr7.ap-northeast-2.eks.amazonaws.com"
#   cluster_ca_certificate = base64decode("LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJYXZVWEFyclgwbjB3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBeU1ETXdOek0xTVRaYUZ3MHpOVEF5TURFd056UXdNVFphTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUURzM0hxMThHSC93Q09PMThBbUo0ZEVWOEMvQ2VVUktyZHlBemNOSnFKalZtWHM0NmhjUXFhdzhLR1UKczNVaXFQN3R6RjFlR2NNUzFuK1dkY1J5bFNmU1pISGo0dHRHTlM5OXcyQWtRcm83dkRYbFRzV21yMXBYbjNVLwpVNzZjRU9nU0k0UnozdC9GaHpoOEQwN1owOGx0UmtuSjl1UVQyOVg3QVJOZm9qTkxkTDJJS3BGQWc2WDhmSVdZCmJiZEpYdEh4d1Q5TDJNaXlxUG1UekxuY0ZBaWZHSTRmTGEvbXR3a1ZmWk1US0VLbHovejRxdnhWT2d4Nk9la00KdTViYTRkQW5oUGtpQ1ZCdXdpTmJ1dkhYZ1NBT3Z0aXpkNzVJTWxuemk4cjJvaVM0MkZHWkMxMUpTcXIvWjV0SgpFTW5QWHJEVm1vWmJhM2FMa2RxNDVqR2pScXZmQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJSdWQzWEpQaDFRSCtLSkVpN25pVEhRbmh6T21qQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQ204Z2wyeGpJUgo4cURMY1BlRnNzbzVHc2JaUGRXYXZjSEpVSVpFbnRUckRoSjlyaTIvY3NLajNwOTcyN0tCSDhIdzhvRW5uZmNOCm5wSU41cmFKYXNmQ0ZkWU95OHY0RlBLNTczSDF1VTl3RWZtZEViUG14VFpGc0lqUFFMS2ZUODZiWk93VE5tTjMKaXUxWExxd0NMbms5MDFjMC9tQng4NWo4SU1jM0s3Y25Bayt5c05rU3Z4b242S0h3NnMzOWg0b05kenRvWkV0Swp2VDdQZkRlQUVadU8vTm5CQmhDd0E3c1lGdUpPbHIyRitKSmE0ZGVzTWlEOUhyMXZMNDBqWm9RbjVTOHFpYkl1CkZCMzN1WEZvODBFUnRGV3QxdHpQN0YxdVNyRk41UlcvMW90TmhUbFVSczBxbTM0VE9ubFFHMVNla1pHT1ovMTMKS1RmU1FGcFNYY3hqCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K")
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args        = ["eks", "get-token", "--cluster-name", "eks-staging-v1"]
#   }
# }

# provider "helm" {
#   kubernetes {
#     host                   = "https://D37F243D1CECB34ADD870D73574EB745.gr7.ap-northeast-2.eks.amazonaws.com"
#     cluster_ca_certificate = base64decode("LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJYXZVWEFyclgwbjB3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBeU1ETXdOek0xTVRaYUZ3MHpOVEF5TURFd056UXdNVFphTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUURzM0hxMThHSC93Q09PMThBbUo0ZEVWOEMvQ2VVUktyZHlBemNOSnFKalZtWHM0NmhjUXFhdzhLR1UKczNVaXFQN3R6RjFlR2NNUzFuK1dkY1J5bFNmU1pISGo0dHRHTlM5OXcyQWtRcm83dkRYbFRzV21yMXBYbjNVLwpVNzZjRU9nU0k0UnozdC9GaHpoOEQwN1owOGx0UmtuSjl1UVQyOVg3QVJOZm9qTkxkTDJJS3BGQWc2WDhmSVdZCmJiZEpYdEh4d1Q5TDJNaXlxUG1UekxuY0ZBaWZHSTRmTGEvbXR3a1ZmWk1US0VLbHovejRxdnhWT2d4Nk9la00KdTViYTRkQW5oUGtpQ1ZCdXdpTmJ1dkhYZ1NBT3Z0aXpkNzVJTWxuemk4cjJvaVM0MkZHWkMxMUpTcXIvWjV0SgpFTW5QWHJEVm1vWmJhM2FMa2RxNDVqR2pScXZmQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJSdWQzWEpQaDFRSCtLSkVpN25pVEhRbmh6T21qQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQ204Z2wyeGpJUgo4cURMY1BlRnNzbzVHc2JaUGRXYXZjSEpVSVpFbnRUckRoSjlyaTIvY3NLajNwOTcyN0tCSDhIdzhvRW5uZmNOCm5wSU41cmFKYXNmQ0ZkWU95OHY0RlBLNTczSDF1VTl3RWZtZEViUG14VFpGc0lqUFFMS2ZUODZiWk93VE5tTjMKaXUxWExxd0NMbms5MDFjMC9tQng4NWo4SU1jM0s3Y25Bayt5c05rU3Z4b242S0h3NnMzOWg0b05kenRvWkV0Swp2VDdQZkRlQUVadU8vTm5CQmhDd0E3c1lGdUpPbHIyRitKSmE0ZGVzTWlEOUhyMXZMNDBqWm9RbjVTOHFpYkl1CkZCMzN1WEZvODBFUnRGV3QxdHpQN0YxdVNyRk41UlcvMW90TmhUbFVSczBxbTM0VE9ubFFHMVNla1pHT1ovMTMKS1RmU1FGcFNYY3hqCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K")
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args        = ["eks", "get-token", "--cluster-name", "eks-staging-v1"]
#     }
#   }
# }