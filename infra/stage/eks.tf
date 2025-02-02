# module "eks-dev1" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 20.31"

#   cluster_name    = "${var.eks_name}-${var.env}-dev1"
#   cluster_version = var.eks_version

#   vpc_id     = module.vpc.vpc_id
#   subnet_ids = module.vpc.public_subnets

#   cluster_endpoint_public_access           = true
#   enable_cluster_creator_admin_permissions = true

#   eks_managed_node_groups = {
#     general = {
#       min_size     = 1
#       max_size     = 10
#       desired_size = 1

#       instance_types = ["t3.xlarge"]
#       capacity_type  = "ON_DEMAND"
#     }
#   }

#   tags = {
#     Environment                                        = var.env
#     Terraform                                          = "true"
# #    "kubernetes.io/cluster/${module.eks.cluster_name}" = "shared"
#   }
# }

# module "eks-dev1_blueprints_addons" {
#   source = "aws-ia/eks-blueprints-addons/aws"
#   version = "~> 1.19" #ensure to update this to the latest/desired version

#   cluster_name      = module.eks-dev1.cluster_name
#   cluster_endpoint  = module.eks-dev1.cluster_endpoint
#   cluster_version   = module.eks-dev1.cluster_version
#   oidc_provider_arn = module.eks-dev1.oidc_provider_arn

#   eks_addons = {
#     # aws-ebs-csi-driver = {
#     #   most_recent = true
#     # }
#     aws-efs-csi-driver = {
#       most_recent = true
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
# #  enable_cluster_proportional_autoscaler = true
# #  enable_karpenter                       = true
#   enable_metrics_server                  = true
# #  enable_external_dns                    = true
# #  enable_cert_manager                    = true

#   tags = {
#     Environment = var.env
#   }
# }

# provider "kubernetes" {
#   host                   = module.eks-dev1.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks-dev1.cluster_certificate_authority_data)
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args        = ["eks", "get-token", "--cluster-name", module.eks-dev1.cluster_name]
#   }
# }

# resource "kubernetes_config_map" "kubernetes_env_vars" {
#   metadata {
#     name      = "kubernetes-env-vars"
#     namespace = "kube-system"
#   }

#   data = {
#     KUBERNETES_MASTER = module.eks-dev1.cluster_endpoint
#     ENV = var.env
#   }
# }

# provider "helm" {
#   kubernetes {
#     host                   = module.eks-dev1.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.eks-dev1.cluster_certificate_authority_data)
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args        = ["eks", "get-token", "--cluster-name", module.eks-dev1.cluster_name]
#     }
#   }
# }

# output "cluster_endpoint" {
#   description = "Endpoint for EKS control plane"
#   value       = module.eks-dev1.cluster_endpoint
# }

# output "eks_cluster_ca_cert" {
#   value = module.eks-dev1.cluster_certificate_authority_data
# }

# # 삭제 시, provider "helm" 안에 참조하는 부분 모두 고정값으로 적어주고 terraform apply
# # Bastion Host의 Cluster-sg 제거!

# provider "kubernetes" {
#   host                   = "https://427839DDC80AC66E4B8FFEFCFFAE08B3.gr7.ap-northeast-2.eks.amazonaws.com"
#   cluster_ca_certificate = base64decode("LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJQ2k4dlNDWmhyRFF3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBeE16QXhNREkzTXpWYUZ3MHpOVEF4TWpneE1ETXlNelZhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUNjU3ljaWFmSW4vV0UzcVF4SmgrU1V2NlNLV2c3WC8xN05SdXdkRGRURHNhRGltMFdTK0dEUGpIN2QKUHVQU3BpcVlVWUxSQXJiNWwzYTJJcWRNOGJSUVhxTjBPZEN4aVJMNm44Z3haazJvMElHMTRMMGNQRE1weUlFSApPZUg2WDdxekdGM0FDRndsRHYwVy8zNEhNRTlJTlNEeis1MWV4TTRCVndDT01PRFBRd3Y1NDZnTElzY2FIRU4rClR0alVteVVFbGVQbldyYmVVN0dpMGJ1elhxcm9tTGJNdnNrUCtNR1daa1h2TFY4d2k5VGp4S2RKd0JOM0pINUoKTnhwdW1ZUkpDUSttYllhVGdURjBjYUJyazJnVGR4eWdNUEY0eXRyRDl3K1lYbHlnVEFoQzlVTkJGNVVBLzNubQpFRWFnNDkyQVpieGRaSzloM1dPU2J1eXhJUHByQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJST09FK3QwczdBZmFjQktoeTVLYm1UR0FnMnNqQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQlJqYWlJZHZacQpjbGxLTHhPZ2RzSDJFWm8vWE5LcGlEbFk5cFFoZ25KelIzVGtHRHlMQ1UxbndSTmhvVTBaOHVvaXoranFyR2dsCkNmVFhNTmxZaEJWdnU5NXAzNXRxemYxTHgzVDY4RkFUNlZyNjNrT1JpaUkxaEpzbnNML1YvNWljQ3JoTU92dlYKSklwVU9kemlzUGFRa2RmSmNGajdBcUNSdEI5N1IrZ2ljZmZaV3dWeTRPNURaYXlRTjB1N0RSdjdoU2Y0TzVCMwpUR1M3MzBPeG1UbDB2S0hlMU9Cd0dJNllVL204empteGUrY1hhUGN6bkZYMVpRWE5wMU1HM0hXajgycjkyTnlICnZjclZtbUFPRmlzbkxrK3VaUHkyK1hra01sM1RYNENCZHQ0ZE8zaWw5SUsyU0traUlJbFo2REpFZ2VGRDR0SzcKN01lVEFwUWxzTXhLCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K")
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args        = ["eks", "get-token", "--cluster-name", "eks-staging-dev1"]
#   }
# }

# provider "helm" {
#   kubernetes {
#     host                   = "https://427839DDC80AC66E4B8FFEFCFFAE08B3.gr7.ap-northeast-2.eks.amazonaws.com"
#     cluster_ca_certificate = base64decode("LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJQ2k4dlNDWmhyRFF3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBeE16QXhNREkzTXpWYUZ3MHpOVEF4TWpneE1ETXlNelZhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUNjU3ljaWFmSW4vV0UzcVF4SmgrU1V2NlNLV2c3WC8xN05SdXdkRGRURHNhRGltMFdTK0dEUGpIN2QKUHVQU3BpcVlVWUxSQXJiNWwzYTJJcWRNOGJSUVhxTjBPZEN4aVJMNm44Z3haazJvMElHMTRMMGNQRE1weUlFSApPZUg2WDdxekdGM0FDRndsRHYwVy8zNEhNRTlJTlNEeis1MWV4TTRCVndDT01PRFBRd3Y1NDZnTElzY2FIRU4rClR0alVteVVFbGVQbldyYmVVN0dpMGJ1elhxcm9tTGJNdnNrUCtNR1daa1h2TFY4d2k5VGp4S2RKd0JOM0pINUoKTnhwdW1ZUkpDUSttYllhVGdURjBjYUJyazJnVGR4eWdNUEY0eXRyRDl3K1lYbHlnVEFoQzlVTkJGNVVBLzNubQpFRWFnNDkyQVpieGRaSzloM1dPU2J1eXhJUHByQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJST09FK3QwczdBZmFjQktoeTVLYm1UR0FnMnNqQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQlJqYWlJZHZacQpjbGxLTHhPZ2RzSDJFWm8vWE5LcGlEbFk5cFFoZ25KelIzVGtHRHlMQ1UxbndSTmhvVTBaOHVvaXoranFyR2dsCkNmVFhNTmxZaEJWdnU5NXAzNXRxemYxTHgzVDY4RkFUNlZyNjNrT1JpaUkxaEpzbnNML1YvNWljQ3JoTU92dlYKSklwVU9kemlzUGFRa2RmSmNGajdBcUNSdEI5N1IrZ2ljZmZaV3dWeTRPNURaYXlRTjB1N0RSdjdoU2Y0TzVCMwpUR1M3MzBPeG1UbDB2S0hlMU9Cd0dJNllVL204empteGUrY1hhUGN6bkZYMVpRWE5wMU1HM0hXajgycjkyTnlICnZjclZtbUFPRmlzbkxrK3VaUHkyK1hra01sM1RYNENCZHQ0ZE8zaWw5SUsyU0traUlJbFo2REpFZ2VGRDR0SzcKN01lVEFwUWxzTXhLCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K")
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args        = ["eks", "get-token", "--cluster-name", "eks-staging-dev1"]
#     }
#   }
# }