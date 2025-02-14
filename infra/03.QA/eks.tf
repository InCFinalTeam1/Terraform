# module "eks-test" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 20.31"

#   cluster_name    = "${var.eks_name}-${var.env}-test"
#   cluster_version = var.eks_version

#   vpc_id     = module.vpc.vpc_id
#   subnet_ids = module.vpc.private_subnets

#   cluster_endpoint_public_access           = true
#   enable_cluster_creator_admin_permissions = true

#   eks_managed_node_groups = {
#     system = {
#       min_size     = 1
#       max_size     = 10
#       desired_size = 1

#       instance_types = ["t3.medium", "t3.large", "c4.large", "c5.large"]
#       capacity_type  = "ON_DEMAND"
#     }
#     # general-purpose = {
#     #   min_size     = 1
#     #   max_size     = 10
#     #   desired_size = 1

#     #   instance_types = ["t3.micro", "t3.small", "t3.medium", "t3.large", "c4.large", "c5.large"]
#     #   capacity_type  = "SPOT"
#     # }
#   }

#   tags = {
#     Environment                                        = var.env
#     Terraform                                          = "true"
# #    "kubernetes.io/cluster/${module.eks.cluster_name}" = "shared"
#   }
# }

# module "eks-test_blueprints_addons" {
#   source = "aws-ia/eks-blueprints-addons/aws"
#   version = "~> 1.19" #ensure to update this to the latest/desired version

#   cluster_name      = module.eks-test.cluster_name
#   cluster_endpoint  = module.eks-test.cluster_endpoint
#   cluster_version   = module.eks-test.cluster_version
#   oidc_provider_arn = module.eks-test.oidc_provider_arn

#   eks_addons = {
#     # aws-ebs-csi-driver = {
#     #   most_recent = true
#     # }
#     aws-efs-csi-driver = {
#       most_recent = true
#       #service_account_role_arn = module.efs_csi_driver_irsa.iam_role_arn 
#     }
#     eks-pod-identity-agent = {
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
# #   enable_cluster_proportional_autoscaler = true
#   enable_karpenter                       = true
#   enable_metrics_server                  = true
#   enable_external_dns                    = true
#   enable_cert_manager                    = true

#   tags = {
#     Environment = var.env
#   }
# }

# # kubernetes_config-map 생성을 위해서 필요
# provider "kubernetes" {
#   host                   = module.eks-test.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks-test.cluster_certificate_authority_data)
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args        = ["eks", "get-token", "--cluster-name", module.eks-test.cluster_name]
#   }
# }

# resource "kubernetes_config_map" "kubernetes_env_vars-test" {
#   metadata {
#     name      = "kubernetes-env-vars-test"
#     namespace = "kube-system"
#     annotations = {
#       "terraform.io/module" = "eks-test"  # 모듈 식별 주석 추가
#     }
#   }

#   data = {
#     KUBERNETES_MASTER = module.eks-test.cluster_endpoint
#     ENG = "test"
#   }
# }

# provider "helm" {
#   kubernetes {
#     host                   = module.eks-test.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.eks-test.cluster_certificate_authority_data)
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args        = ["eks", "get-token", "--cluster-name", module.eks-test.cluster_name]
#     }
#   }
# }

# output "cluster-test_endpoint" {
#   description = "Endpoint for EKS control plane"
#   value       = module.eks-test.cluster_endpoint
# }

# output "eks_cluster-test_ca_cert" {
#   value = module.eks-test.cluster_certificate_authority_data
# }

# # 삭제 시, provider "helm" 안에 참조하는 부분 모두 고정값으로 적어주고 terraform apply
# provider "kubernetes" {
#   host                   = "https://C85AFDCF2BA61AEA6F2C88E9EA8667C3.yl4.ap-northeast-2.eks.amazonaws.com"
#   cluster_ca_certificate = base64decode("LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJQmpWZGwwU3JGR2d3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBeU1URXdOREl5TXpSYUZ3MHpOVEF5TURrd05ESTNNelJhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUURaaWtsS0U0TEFTcngzR3diek1kNGxMQy9FMjlwK1RkU0RUeThaVk9FQjZDcmFwcHZpaFRQM3J5TGkKcTRoc0xrNk9HUHBVVU9kQ2FMRlF6Y0ZrV1VQTkl0bmNVRloyZ2JHWkdhZTFsSThSTzdSOWNSZ0JiWjRSOUo5SwpWNVc0eHk5aHQwZGh4QWNjVURIMnRjTzlFRnFNWU12TDJCRHAwS1dlcStkZGo5eitDa2J6VHY1U3BMOEd1dTVRCml1bTZIMHF6aHp4VzJ6dlI3Yk12cGtURXRLamloZHovZnRVN2NQbEZRalk3dVhUU2JTOUUxa2paeFZyMlc3NFkKbUZXUmtuR0pTUDB5aTdDUzJsNDUrRmV0OTBzallUNTF3NjFPOFF6alliaWFuUjVQamQxVTZXMTRsVjViRWZybgo3R1lhTjdPU0N3dFQ3dXMzdytjdDNMM0ovRVNWQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJTQ3FrV1hzVUk0Wk5uczMrUEp4YzFhOFNtK1BEQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQmFyTGczdk9XKwo2VXh5SWkwWW1wOGxVd3poYUFDYmxVWlJDb0owZ0xqQkVEbngyR1UyRUhEdDlhdUFFM3IwMG9VYnU4Q2NYRXBaCmZCLzBMdW9PMjBCSUowbjFkN1plMk5mRXBhWkhwQzdXV05FcGs3cXpjT2pwM0JwckVoUHNTN1hoTWFNcWliSHoKRkpwb3Vpak5ndDR6Zlc4dnNkT1lsR29sRzB1ZFRBNE55THpNTWZzQkUvZWN2YnpiWno4QVJDVWFFTzFHcEtYMQpFTkxzWnJHT3hzdkl6MTZGWCtWMk90Q0JUVHI3L0NWNi9QenpxWkZYVXZPZjI5ejJBQU1teEppQ0pGTTFDdkJaCkV2ZkhMWWllNmhnck90TGdCWEhUVjBoUGJEWlh4TlFubzdHM0l5QTZrMTJQN29wbFRZQ0pMWEZnUnEya005RXgKdkpaY3VaazZEWHpzCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K")
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args        = ["eks", "get-token", "--cluster-name", "eks-qa-test"]
#   }
# }

# provider "helm" {
#   kubernetes {
#     host                   = "https://C85AFDCF2BA61AEA6F2C88E9EA8667C3.yl4.ap-northeast-2.eks.amazonaws.com"
#     cluster_ca_certificate = base64decode("LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJQmpWZGwwU3JGR2d3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBeU1URXdOREl5TXpSYUZ3MHpOVEF5TURrd05ESTNNelJhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUURaaWtsS0U0TEFTcngzR3diek1kNGxMQy9FMjlwK1RkU0RUeThaVk9FQjZDcmFwcHZpaFRQM3J5TGkKcTRoc0xrNk9HUHBVVU9kQ2FMRlF6Y0ZrV1VQTkl0bmNVRloyZ2JHWkdhZTFsSThSTzdSOWNSZ0JiWjRSOUo5SwpWNVc0eHk5aHQwZGh4QWNjVURIMnRjTzlFRnFNWU12TDJCRHAwS1dlcStkZGo5eitDa2J6VHY1U3BMOEd1dTVRCml1bTZIMHF6aHp4VzJ6dlI3Yk12cGtURXRLamloZHovZnRVN2NQbEZRalk3dVhUU2JTOUUxa2paeFZyMlc3NFkKbUZXUmtuR0pTUDB5aTdDUzJsNDUrRmV0OTBzallUNTF3NjFPOFF6alliaWFuUjVQamQxVTZXMTRsVjViRWZybgo3R1lhTjdPU0N3dFQ3dXMzdytjdDNMM0ovRVNWQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJTQ3FrV1hzVUk0Wk5uczMrUEp4YzFhOFNtK1BEQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQmFyTGczdk9XKwo2VXh5SWkwWW1wOGxVd3poYUFDYmxVWlJDb0owZ0xqQkVEbngyR1UyRUhEdDlhdUFFM3IwMG9VYnU4Q2NYRXBaCmZCLzBMdW9PMjBCSUowbjFkN1plMk5mRXBhWkhwQzdXV05FcGs3cXpjT2pwM0JwckVoUHNTN1hoTWFNcWliSHoKRkpwb3Vpak5ndDR6Zlc4dnNkT1lsR29sRzB1ZFRBNE55THpNTWZzQkUvZWN2YnpiWno4QVJDVWFFTzFHcEtYMQpFTkxzWnJHT3hzdkl6MTZGWCtWMk90Q0JUVHI3L0NWNi9QenpxWkZYVXZPZjI5ejJBQU1teEppQ0pGTTFDdkJaCkV2ZkhMWWllNmhnck90TGdCWEhUVjBoUGJEWlh4TlFubzdHM0l5QTZrMTJQN29wbFRZQ0pMWEZnUnEya005RXgKdkpaY3VaazZEWHpzCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K")
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args        = ["eks", "get-token", "--cluster-name", "eks-qa-test"]
#     }
#   }
# }