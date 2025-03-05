module "eks-test" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = "${var.eks_name}-${var.env}"
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

module "eks-test_blueprints_addons" {
  depends_on = [module.eks-test]
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.19" #ensure to update this to the latest/desired version

  cluster_name      = module.eks-test.cluster_name
  cluster_endpoint  = module.eks-test.cluster_endpoint
  cluster_version   = module.eks-test.cluster_version
  oidc_provider_arn = module.eks-test.oidc_provider_arn

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

  enable_aws_load_balancer_controller    = true
#  enable_cluster_proportional_autoscaler = true
  enable_kube_prometheus_stack           = true
  enable_metrics_server                  = true
  enable_external_dns                    = true
  enable_argocd                          = true
  enable_karpenter                       = true
  karpenter_enable_spot_termination      = true
#   cert_manager_route53_hosted_zone_arns = ["arn:aws:route53::227250033304:hostedzone/Z055454627IATSRLKVXTQ"]

  tags = {
    Environment = var.env
  }
}

# kubernetes_config-map 생성을 위해서 필요
provider "kubernetes" {
  host                   = module.eks-test.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks-test.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks-test.cluster_name]
  }
}

resource "kubernetes_config_map" "kubernetes_env_vars" {
  depends_on = [module.eks-test]

  metadata {
    name      = "kubernetes-env-vars"
    namespace = "kube-system"
  }

  data = {
    KUBERNETES_MASTER = module.eks-test.cluster_endpoint
    ENV = var.env
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks-test.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks-test.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks-test.cluster_name]
    }
  }
}

output "cluster-test_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks-test.cluster_endpoint
}

output "eks_cluster-test_ca_cert" {
  value = module.eks-test.cluster_certificate_authority_data
}

output "karpenter_node_role_name-test" {
  description = "Karpenter 노드 역할 이름"
  value       = module.eks-test_blueprints_addons.karpenter.node_iam_role_name
}

# # 삭제 시, provider "helm" 안에 참조하는 부분 모두 고정값으로 적어주고 terraform apply
# provider "kubernetes" {
#   host                   = "https://13D6177EF89A65A2EAA76DFAA9E8DD14.gr7.ap-northeast-2.eks.amazonaws.com"
#   cluster_ca_certificate = base64decode("LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJWnBiTWRqbGZqZHN3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBeU1qY3dNelEyTURGYUZ3MHpOVEF5TWpVd016VXhNREZhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUNvSGVhMnUyV2doajRtVE5xejFrNkVXQTdJbGV1YytnLzZ3dkhaYVcwdG9IN3p0Z2dXaDNMUXNtQk4Kc1FEMUJpa2I0TDNtV1l1U1ZDU2JOaVJoMmVnWVliOGdnYVNkcEJya05XTW83bUk3Nk40bVYvRU9HL3BwaXNFTgo2ZFpVaWRrS3lPNG5rbDUzL0h2TjJISHlvM1BVQTJxdmhqU1Uvc1MxSFdOb0VpdUVxMFdQUU5Ja1VubWUrUzE0CjhQeDFqWDdRbC9pMkxqK1M0Sm5ZdGc3dU5jZk0vbHQzc1IvWXUybmJUWGVVYnFqZGtzZTcyQk9wUjdBVVlhZm4KR2lkWm16cDJTTnMrc2QvWk5sYmh6WEVHbDUvMmJsTTU5S05NZXlPczlxczZYeHNOV2hqYWRETHFBSThGVmJKNwpzMzk2NlhWbGw1djBaUThUdC9WKzZlMmR4L3psQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJTL1RXNjZsZ2VnaWtUejc4alUvZUszWExwblNUQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQlFjRDRhSmRUcAp5aGpEbGZyQlVlb3FXSytzZElpamtyQW5oSnBSd2YyZDNWMjl3a2RFM28xazlNU3FIMzVIcERneTJtdytqY0ZuCkUzM2NySC9kZ25Ec2RDLytNVEtCRzRqRFZmZ1cwcHVTeHFqelRqODNlRnBFc3JmN1JmbzlVTWI4cnUxUE41NVAKSEl5K285ZGhVNWVINzlqQ2t4ckxzZjlSZi9zR21oOGFnVGtUMGE3T1dlU25OQzJ6dnBoMlJDVXlwb0xCWGtkdgpGeWh1WHZKRElzOGFxUGFwV2NJeWNUekRkR2VMRkZTdU5wNFRBdlJ5SFNRZHRxM0NyN0l2WnZtYkpFVXVrRHBlCnZHTEhRb3dLaGRZZVA1ZlhVZUJ0cTJxcDUwUjdyQ3N1VkJkU0k3YTJJVS9BS1pSZ0Z2V1RRY0Y5T1FzRm9BWVkKbDZ2ZnUyajMwbWZJCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K")
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args        = ["eks", "get-token", "--cluster-name", "eks-qa"]
#   }
# }

# provider "helm" {
#   kubernetes {
#     host                   = "https://13D6177EF89A65A2EAA76DFAA9E8DD14.gr7.ap-northeast-2.eks.amazonaws.com"
#     cluster_ca_certificate = base64decode("LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJWnBiTWRqbGZqZHN3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBeU1qY3dNelEyTURGYUZ3MHpOVEF5TWpVd016VXhNREZhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUNvSGVhMnUyV2doajRtVE5xejFrNkVXQTdJbGV1YytnLzZ3dkhaYVcwdG9IN3p0Z2dXaDNMUXNtQk4Kc1FEMUJpa2I0TDNtV1l1U1ZDU2JOaVJoMmVnWVliOGdnYVNkcEJya05XTW83bUk3Nk40bVYvRU9HL3BwaXNFTgo2ZFpVaWRrS3lPNG5rbDUzL0h2TjJISHlvM1BVQTJxdmhqU1Uvc1MxSFdOb0VpdUVxMFdQUU5Ja1VubWUrUzE0CjhQeDFqWDdRbC9pMkxqK1M0Sm5ZdGc3dU5jZk0vbHQzc1IvWXUybmJUWGVVYnFqZGtzZTcyQk9wUjdBVVlhZm4KR2lkWm16cDJTTnMrc2QvWk5sYmh6WEVHbDUvMmJsTTU5S05NZXlPczlxczZYeHNOV2hqYWRETHFBSThGVmJKNwpzMzk2NlhWbGw1djBaUThUdC9WKzZlMmR4L3psQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJTL1RXNjZsZ2VnaWtUejc4alUvZUszWExwblNUQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQlFjRDRhSmRUcAp5aGpEbGZyQlVlb3FXSytzZElpamtyQW5oSnBSd2YyZDNWMjl3a2RFM28xazlNU3FIMzVIcERneTJtdytqY0ZuCkUzM2NySC9kZ25Ec2RDLytNVEtCRzRqRFZmZ1cwcHVTeHFqelRqODNlRnBFc3JmN1JmbzlVTWI4cnUxUE41NVAKSEl5K285ZGhVNWVINzlqQ2t4ckxzZjlSZi9zR21oOGFnVGtUMGE3T1dlU25OQzJ6dnBoMlJDVXlwb0xCWGtkdgpGeWh1WHZKRElzOGFxUGFwV2NJeWNUekRkR2VMRkZTdU5wNFRBdlJ5SFNRZHRxM0NyN0l2WnZtYkpFVXVrRHBlCnZHTEhRb3dLaGRZZVA1ZlhVZUJ0cTJxcDUwUjdyQ3N1VkJkU0k3YTJJVS9BS1pSZ0Z2V1RRY0Y5T1FzRm9BWVkKbDZ2ZnUyajMwbWZJCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K")
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args        = ["eks", "get-token", "--cluster-name", "eks-qa"]
#     }
#   }
# }