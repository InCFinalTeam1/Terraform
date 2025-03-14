# module "eks-v1" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 20.31"

#   cluster_name    = "${var.eks_name}-${var.env}-v2"
#   cluster_version = var.eks_version

#   vpc_id     = module.vpc.vpc_id
#   subnet_ids = module.vpc.private_subnets 

#   cluster_endpoint_public_access           = true  # Test여서 허용
#   enable_cluster_creator_admin_permissions = true

#   eks_managed_node_groups = {
#     system = {
#       min_size     = 1
#       max_size     = 10
#       desired_size = 1

# #      instance_types = ["t3.medium", "t3.large", "c4.large", "c5.large"]
#       instance_types = ["t3.xlarge"]
#       capacity_type  = "SPOT"
#     }
#   }
#   tags = {
#     Environment                                        = var.env
#     Terraform                                          = "true"
# #    "kubernetes.io/cluster/${module.eks.cluster_name}" = "shared"
#   }
# }

# module "eks-v1_blueprints_addons" {
#   depends_on = [module.eks-v1]
#   source = "aws-ia/eks-blueprints-addons/aws"
#   version = "~> 1.19" #ensure to update this to the latest/desired version

#   cluster_name      = module.eks-v1.cluster_name
#   cluster_endpoint  = module.eks-v1.cluster_endpoint
#   cluster_version   = module.eks-v1.cluster_version
#   oidc_provider_arn = module.eks-v1.oidc_provider_arn

#   eks_addons = {
#     aws-ebs-csi-driver = {
#       most_recent = true
#     }
#     coredns = {
#       most_recent = true
#     }
#     vpc-cni = {
#       most_recent = true
#     }
#     kube-proxy = {
#       most_recent = true
#     }
#   }

#   enable_aws_load_balancer_controller    = true
# #  enable_cluster_proportional_autoscaler = true
#   enable_kube_prometheus_stack           = true
#   enable_metrics_server                  = true
#   enable_external_dns                    = true
#   enable_argocd                          = true
#   enable_karpenter                       = true
#   karpenter_enable_spot_termination      = true
# #   cert_manager_route53_hosted_zone_arns = ["arn:aws:route53::227250033304:hostedzone/Z055454627IATSRLKVXTQ"]

#   tags = {
#     Environment = var.env
#   }
# }

# # kubernetes_config-map 생성을 위해서 필요
# provider "kubernetes" {
#   host                   = module.eks-v1.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks-v1.cluster_certificate_authority_data)
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args        = ["eks", "get-token", "--cluster-name", module.eks-v1.cluster_name]
#   }
# }

# resource "kubernetes_config_map" "kubernetes_env_vars" {
#   depends_on = [module.eks-v1, module.eks-v1_blueprints_addons]

#   metadata {
#     name      = "kubernetes-env-vars"
#     namespace = "kube-system"
#   }

#   data = {
#     KUBERNETES_MASTER = module.eks-v1.cluster_endpoint
#     ENV = var.env
#   }
# }

# provider "helm" {
#   kubernetes {
#     host                   = module.eks-v1.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.eks-v1.cluster_certificate_authority_data)
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args        = ["eks", "get-token", "--cluster-name", module.eks-v1.cluster_name]
#     }
#   }
# }

# # resource "null_resource" "run_post_script" {
# #   depends_on = [module.eks-v1, module.eks-v1_blueprints_addons]

# #   provisioner "local-exec" {
# #     environment = {
# #       CLUSTER_NAME = module.eks-v1.cluster_name
# #     }
# #     command = "bash ./karpentersh"
# #   }
# # }

# output "cluster-v1_endpoint" {
#   description = "Endpoint for EKS control plane"
#   value       = module.eks-v1.cluster_endpoint
# }

# output "eks_cluster-v1_ca_cert" {
#   value = module.eks-v1.cluster_certificate_authority_data
# }

# output "karpenter_node_role_name" {
#   description = "Karpenter 노드 역할 이름"
#   value       = module.eks-v1_blueprints_addons.karpenter.node_iam_role_name
# }

# # 삭제 시, provider "helm" 안에 참조하는 부분 모두 고정값으로 적어주고 terraform apply
# # Bastion Host의 Cluster-sg 제거!

# provider "kubernetes" {
#   host                   = "https://9E78D9DC31E55F7EC143DF25F2BE9420.yl4.ap-northeast-2.eks.amazonaws.com"
#   cluster_ca_certificate = base64decode("LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJSEQxa0hVVWlzZDR3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBek1EUXdNVFF3TWpOYUZ3MHpOVEF6TURJd01UUTFNak5hTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUM2dTkrSFNQa2lFVjhRZlV4U2FOYzFWbzd4U3RvazR1WStLT2tsQTdDajZzN0w1dWhvWk1zZzdRQ2oKcUtQbTNiempQUFNSNFc5eUNteEk4TFVHZ0wyK2ljVG94V2JwcFRlS1V3SU9pWFl0WlprNUM5MjkrNU9WZi82WgpSQzNKREZlSnNzRzE1dTJGdE1wU3E4dWl5UlhOMFlablVHcC9wTm9ZMW9xRWRHbzFCNk1XaWg4c0tFSnEyT0hECm5MUWYwR3A0QmpzWmN6M1R0VmJXajBGcWZwbTdldmtkKzNaV0tYaWlPU0drb21wSnE0ZWRleFVOVzU5SjdVUEUKMkNlK1o4SFordjhTU3EvM210bmNmb1o5aE5UNTRvSDZWeWxpMjFuenNTTWZjbmxTZHdhYWFJdkY2Wklra0IwMQpUczEvMjV2blg1MWJBTXY4dzczTHVQZnFPWEdQQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJTWThaUGlwVVZMVXVlbHhJaS84LzNlc0dLQzB6QVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQXc1STZKYWF1Kwp3QmFLK1lqYWlQdUdleUlEMzBJcm9CelQ0Tnp6MUlJdUhIOUZtWCtHR2JyNHVKSzY1U3lkZFFxa1YvQWJBR0FrCjVKNkhncnozMWIwazhJRjFQNUkvbGRFOXlkZFdwMzZiUE5hQURxcFFUV3AzV05ZTmlTaG42M1RIY3dBbndPczgKdStEd0pwN080T2dJNkNqWHE0NnowRHM1THBDSFVCbTd0UlAwcXFvb3pBRXJmaE9uVzNNMyt6ckVtK3NUQ2lVTAphR3ZjVENUMVJZTjBXVjJBTTlXSjRDTE5QRmdkSlFCSFlZSHh5TUJneThzWkthL2d1WFVZeVNWN1NvSk5jUllKCnpsbG9mTVlHUTQzL2dZUmZjWlc0cW92QjNQbHRvQUd2bDhZZEFCSUlTK0JFZDRwWFVEY1QwM1BOMXlpTEdmUGoKZUk5OHhkOXpjWFhpCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K")
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args        = ["eks", "get-token", "--cluster-name", "eks-staging-v2"]
#   }
# }

# provider "helm" {
#   kubernetes {
#     host                   = "https://9E78D9DC31E55F7EC143DF25F2BE9420.yl4.ap-northeast-2.eks.amazonaws.com"
#     cluster_ca_certificate = base64decode("LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJSEQxa0hVVWlzZDR3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBek1EUXdNVFF3TWpOYUZ3MHpOVEF6TURJd01UUTFNak5hTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUM2dTkrSFNQa2lFVjhRZlV4U2FOYzFWbzd4U3RvazR1WStLT2tsQTdDajZzN0w1dWhvWk1zZzdRQ2oKcUtQbTNiempQUFNSNFc5eUNteEk4TFVHZ0wyK2ljVG94V2JwcFRlS1V3SU9pWFl0WlprNUM5MjkrNU9WZi82WgpSQzNKREZlSnNzRzE1dTJGdE1wU3E4dWl5UlhOMFlablVHcC9wTm9ZMW9xRWRHbzFCNk1XaWg4c0tFSnEyT0hECm5MUWYwR3A0QmpzWmN6M1R0VmJXajBGcWZwbTdldmtkKzNaV0tYaWlPU0drb21wSnE0ZWRleFVOVzU5SjdVUEUKMkNlK1o4SFordjhTU3EvM210bmNmb1o5aE5UNTRvSDZWeWxpMjFuenNTTWZjbmxTZHdhYWFJdkY2Wklra0IwMQpUczEvMjV2blg1MWJBTXY4dzczTHVQZnFPWEdQQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJTWThaUGlwVVZMVXVlbHhJaS84LzNlc0dLQzB6QVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQXc1STZKYWF1Kwp3QmFLK1lqYWlQdUdleUlEMzBJcm9CelQ0Tnp6MUlJdUhIOUZtWCtHR2JyNHVKSzY1U3lkZFFxa1YvQWJBR0FrCjVKNkhncnozMWIwazhJRjFQNUkvbGRFOXlkZFdwMzZiUE5hQURxcFFUV3AzV05ZTmlTaG42M1RIY3dBbndPczgKdStEd0pwN080T2dJNkNqWHE0NnowRHM1THBDSFVCbTd0UlAwcXFvb3pBRXJmaE9uVzNNMyt6ckVtK3NUQ2lVTAphR3ZjVENUMVJZTjBXVjJBTTlXSjRDTE5QRmdkSlFCSFlZSHh5TUJneThzWkthL2d1WFVZeVNWN1NvSk5jUllKCnpsbG9mTVlHUTQzL2dZUmZjWlc0cW92QjNQbHRvQUd2bDhZZEFCSUlTK0JFZDRwWFVEY1QwM1BOMXlpTEdmUGoKZUk5OHhkOXpjWFhpCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K")
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args        = ["eks", "get-token", "--cluster-name", "eks-staging-v2"]
#     }
#   }
# }