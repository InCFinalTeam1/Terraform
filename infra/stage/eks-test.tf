# module "eks-test" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 20.31"

#   cluster_name    = "${var.eks_name}-${var.env}-test"
#   cluster_version = var.eks_version

#   vpc_id     = module.vpc.vpc_id
#   subnet_ids = module.vpc.public_subnets

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
#     general-purpose = {
#       min_size     = 1
#       max_size     = 10
#       desired_size = 1

#       instance_types = ["t3.micro", "t3.small", "t3.medium", "t3.large", "c4.large", "c5.large"]
#       capacity_type  = "SPOT"
#     }
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
# #
#   providers = {
#     kubernetes = kubernetes.test
#     helm       = helm.test
#   }
# #
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
# #  enable_cluster_proportional_autoscaler = true
# #  enable_karpenter                       = true
#   enable_metrics_server                  = true
# #  enable_external_dns                    = true
# #  enable_cert_manager                    = true

#   tags = {
#     Environment = var.env
#   }
# }

# # kubernetes_config-map 생성을 위해서 필요
# provider "kubernetes" {
#   alias = "test"
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
#   alias = "test"
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

# output "eks_cluster_ca_cert" {
#   value = module.eks-test.cluster_certificate_authority_data
# }

# # 삭제 시, provider "helm" 안에 참조하는 부분 모두 고정값으로 적어주고 terraform apply