module "eks-v1" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = "${var.eks_name}-${var.env}-v2"
  cluster_version = var.eks_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets 

  cluster_endpoint_public_access           = true  # Test여서 허용
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    system = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t3.medium", "t3.large", "c4.large", "c5.large"]
      capacity_type  = "ON_DEMAND"
    }
  }
  tags = {
    Environment                                        = var.env
    Terraform                                          = "true"
#    "kubernetes.io/cluster/${module.eks.cluster_name}" = "shared"
  }
}

module "eks-v1_blueprints_addons" {
  depends_on = [module.eks-v1]
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.19" #ensure to update this to the latest/desired version

  cluster_name      = module.eks-v1.cluster_name
  cluster_endpoint  = module.eks-v1.cluster_endpoint
  cluster_version   = module.eks-v1.cluster_version
  oidc_provider_arn = module.eks-v1.oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
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
  enable_argocd                          = true

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
  depends_on = [module.eks-v1]

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

output "cluster-v1_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks-v1.cluster_endpoint
}

output "eks_cluster-v1_ca_cert" {
  value = module.eks-v1.cluster_certificate_authority_data
}

output "karpenter_node_role_name" {
  description = "Karpenter 노드 역할 이름"
  value       = module.eks-v1_blueprints_addons.karpenter.node_iam_role_name
}

# # 삭제 시, provider "helm" 안에 참조하는 부분 모두 고정값으로 적어주고 terraform apply
# # Bastion Host의 Cluster-sg 제거!

# provider "kubernetes" {
#   host                   = "https://DD49EC9F0C1630C46806D8FA7A4A227D.sk1.ap-northeast-2.eks.amazonaws.com"
#   cluster_ca_certificate = base64decode("LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJZUcvbmkvbDZQWWd3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBeU1UUXdNREUwTWpOYUZ3MHpOVEF5TVRJd01ERTVNak5hTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUNiS1Y3dVptWDNSeXJLQURwUlQ0MHZDNSt1YitOUXh1WnVGT0RwUGJVZ3FMOTVNNWY3Q3BqNnB3SnMKTlRRRm03QjNHS3VxZ0pzUEZOV3F0VCtVd0laN3VFV0hxc1dxWk1Pa2xsUE1ORVJDcUFwV0UyRzhJUjZza0MwaQpzTnJ5UEx2MVJHUDk5WStRVjc1RDErSVYyb0E0MUlrTG4xNmZwNkhKaEMwVDhPbXorSWtZbzVRS1FQeUZ1NWR3CjM0bThHcVhTK205RmxGdFRaUURJTERzQkt2dUMvRk9KTjVOWHZCSmN1V0NYdytEZzhTZUVsa1lyeTRLZVhvREEKKzhYVFlaaVFSY2VnMlJnMmlNY2ZjaFc2VG45OXFRUjlPdDUvb3F4VW1kUUFGVFJUU1ZBdFQzby9FR25mVHBxYgpuU1ZQS1dsVk4wM3NjaEVPKzR2K2pXdGpUdDA3QWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJTY1ZwRFdIcW8xY2tiRmh6NHdFTDVvNW1NY3Z6QVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQWxNQkZwQWx6bwo2WU56NCsvaHM0SEFiVldvdXBRY3JjZUpiSzVtSm9Mdm82R0tuY3VjSm5kRkllN2gwQ1hsSmpsak5WQ1VlNzlyCmRsS29raExrVi9TNEY2Ujhja25FU1k0OVdtNTVKbWZvbCs1TlhKRHZvTlUvWVgzbjNpN2VncDNYVHJBN2tTaHIKMm8xdVUzbGdhdk0wazhtanJHYlppRGRYSmN3M0xIU0JMSHE1dlpKbk1aNEtBeWhFK2VETTVRU2hhNmhLUExwcApnMGlybDJZODNNdkw0NDhZWk0rNXljRVMzNEkxenhlU25yY1NncEpEVE9qV3RvMmc2MStvbnlnKzQ4ZGNUWjNECjI4emxmejJXaUI5NHh0V0xtbkN6VGx4ZVFUSVQzUkt4UXA0TEphMFFrS1dpWFlwTmZCeFdjM1hLMjQ3aUJRcDcKK2lkYmQyNnFPSEtzCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K")
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args        = ["eks", "get-token", "--cluster-name", "eks-staging-v2"]
#   }
# }

# provider "helm" {
#   kubernetes {
#     host                   = "https://DD49EC9F0C1630C46806D8FA7A4A227D.sk1.ap-northeast-2.eks.amazonaws.com"
#     cluster_ca_certificate = base64decode("LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJZUcvbmkvbDZQWWd3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBeU1UUXdNREUwTWpOYUZ3MHpOVEF5TVRJd01ERTVNak5hTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUNiS1Y3dVptWDNSeXJLQURwUlQ0MHZDNSt1YitOUXh1WnVGT0RwUGJVZ3FMOTVNNWY3Q3BqNnB3SnMKTlRRRm03QjNHS3VxZ0pzUEZOV3F0VCtVd0laN3VFV0hxc1dxWk1Pa2xsUE1ORVJDcUFwV0UyRzhJUjZza0MwaQpzTnJ5UEx2MVJHUDk5WStRVjc1RDErSVYyb0E0MUlrTG4xNmZwNkhKaEMwVDhPbXorSWtZbzVRS1FQeUZ1NWR3CjM0bThHcVhTK205RmxGdFRaUURJTERzQkt2dUMvRk9KTjVOWHZCSmN1V0NYdytEZzhTZUVsa1lyeTRLZVhvREEKKzhYVFlaaVFSY2VnMlJnMmlNY2ZjaFc2VG45OXFRUjlPdDUvb3F4VW1kUUFGVFJUU1ZBdFQzby9FR25mVHBxYgpuU1ZQS1dsVk4wM3NjaEVPKzR2K2pXdGpUdDA3QWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJTY1ZwRFdIcW8xY2tiRmh6NHdFTDVvNW1NY3Z6QVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQWxNQkZwQWx6bwo2WU56NCsvaHM0SEFiVldvdXBRY3JjZUpiSzVtSm9Mdm82R0tuY3VjSm5kRkllN2gwQ1hsSmpsak5WQ1VlNzlyCmRsS29raExrVi9TNEY2Ujhja25FU1k0OVdtNTVKbWZvbCs1TlhKRHZvTlUvWVgzbjNpN2VncDNYVHJBN2tTaHIKMm8xdVUzbGdhdk0wazhtanJHYlppRGRYSmN3M0xIU0JMSHE1dlpKbk1aNEtBeWhFK2VETTVRU2hhNmhLUExwcApnMGlybDJZODNNdkw0NDhZWk0rNXljRVMzNEkxenhlU25yY1NncEpEVE9qV3RvMmc2MStvbnlnKzQ4ZGNUWjNECjI4emxmejJXaUI5NHh0V0xtbkN6VGx4ZVFUSVQzUkt4UXA0TEphMFFrS1dpWFlwTmZCeFdjM1hLMjQ3aUJRcDcKK2lkYmQyNnFPSEtzCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K")
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args        = ["eks", "get-token", "--cluster-name", "eks-staging-v2"]
#     }
#   }
# }