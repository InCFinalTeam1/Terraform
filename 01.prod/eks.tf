module "eks-prod" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = "${var.eks_name}-${var.env}"
  cluster_version = var.eks_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets 

  cluster_endpoint_public_access           = true  
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    system = {
      min_size     = 3
      max_size     = 10
      desired_size = 3

#      instance_types = ["t3.medium", "t3.large", "c4.large", "c5.large"]
      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
    }
  }
  tags = {
    Environment                                        = var.env
    Terraform                                          = "true"
#    "kubernetes.io/cluster/${module.eks.cluster_name}" = "shared"
  }
}

#####################

# # terraform apply로 삭제 시, provider "helm" 안에 참조하는 부분 모두 고정값으로 적어주고 terraform apply
# # Bastion Host의 Cluster-sg 제거!

# provider "kubernetes" {
#   host                   = "https://CACD6B9D5B41E580691390F798981925.gr7.ap-northeast-2.eks.amazonaws.com"
#   cluster_ca_certificate = base64decode("LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJR2dadzQwT0htVU13RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBek1EUXdNelE1TlRkYUZ3MHpOVEF6TURJd016VTBOVGRhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUURxYXJKTjBVVmNtQWdjYVgwU3duR0VvZVBHN3pMSEQ4RHAyVzh0RlNPQU5oZ05aOU9xMG52R3MvM0oKN0hVdkMrMUQvdGxWNk5vb1BJNTd3SmJ4V1VjcEIyMzB5aHI4QUhoTS9QQ0hMMzVzZTBkT0Y5TnZWdXZ3U0E1RgowelQ3ZWJxM2tPd1JjVTVrcTNWaTBPbmo0SGhEQkthbENaTlo4bm1YVEhNbTl1ZGVDZVZkeVQ3cUZVSEdhMmtyClhpMW1ZVFgxdkVzYmFmakhQZU4yTDZBQ3VBdWJHeGdabVllNDluVTBxVENPT2FOR3h6MCttY3pwd1Bmdk5mWEsKSTVjMFA2VDNaUHhCekVXZ1dsZmljTjhyWnJKaHNIajhnd2lvcXFHTUo4bFo0OSt4N2JRRllINU8rUitKSXhqLwpFOTRhYklwbzZKQURLNFJDcU51MEJZdjk2ZXgxQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJST0ZsSW5Tc0tqQllzNHRpVzlhZzJPWmVGK05UQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQ1Nod1VnbjNVaAppUm5MU29oc0pWOHFYU3RFMHg5KzU3RzFhMDZzZW4vVWJVYUdFRGpFZ3dNZ09IdWl4eExnWUJ5NTNNdlNBck9NCjdvcUF2REdyaHpyVVphbkpMQzJFZWErSWlGNTM0OFpPdUc5Q0Z4cWRWMnJkcG9SQURObjE5M1kxbWdVc0ErSnYKS0Y3ZWowN2QwVDdaRDB1QXhJanhJaXp6aVpQblczeXpUakp6Z1F4NVVWbFBzcGovTURrU1FZdGV0K2NDMjhBcwpCZmRiTzc3VzBycHl5UHcwZUVSZDA5VzNEaGxnY2JONVBLTEt5Z1NHQitHMi9JYVNYK0dUbTd6d0xqbEIraHhzCmxlRG9HWkk0N1hBeFk4djFaVk1LbFZlTmVMaGZKdzNoc0xTOG5ONDRHSXVBaWlPM3djVUtJMm1COE1EZHljOGIKU3BYYStJUWc3a0VsCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K")
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args        = ["eks", "get-token", "--cluster-name", "eks-prod"]
#   }
# }

# provider "helm" {
#   kubernetes {
#     host                   = "https://CACD6B9D5B41E580691390F798981925.gr7.ap-northeast-2.eks.amazonaws.com"
#     cluster_ca_certificate = base64decode("LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJR2dadzQwT0htVU13RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBek1EUXdNelE1TlRkYUZ3MHpOVEF6TURJd016VTBOVGRhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUURxYXJKTjBVVmNtQWdjYVgwU3duR0VvZVBHN3pMSEQ4RHAyVzh0RlNPQU5oZ05aOU9xMG52R3MvM0oKN0hVdkMrMUQvdGxWNk5vb1BJNTd3SmJ4V1VjcEIyMzB5aHI4QUhoTS9QQ0hMMzVzZTBkT0Y5TnZWdXZ3U0E1RgowelQ3ZWJxM2tPd1JjVTVrcTNWaTBPbmo0SGhEQkthbENaTlo4bm1YVEhNbTl1ZGVDZVZkeVQ3cUZVSEdhMmtyClhpMW1ZVFgxdkVzYmFmakhQZU4yTDZBQ3VBdWJHeGdabVllNDluVTBxVENPT2FOR3h6MCttY3pwd1Bmdk5mWEsKSTVjMFA2VDNaUHhCekVXZ1dsZmljTjhyWnJKaHNIajhnd2lvcXFHTUo4bFo0OSt4N2JRRllINU8rUitKSXhqLwpFOTRhYklwbzZKQURLNFJDcU51MEJZdjk2ZXgxQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJST0ZsSW5Tc0tqQllzNHRpVzlhZzJPWmVGK05UQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQ1Nod1VnbjNVaAppUm5MU29oc0pWOHFYU3RFMHg5KzU3RzFhMDZzZW4vVWJVYUdFRGpFZ3dNZ09IdWl4eExnWUJ5NTNNdlNBck9NCjdvcUF2REdyaHpyVVphbkpMQzJFZWErSWlGNTM0OFpPdUc5Q0Z4cWRWMnJkcG9SQURObjE5M1kxbWdVc0ErSnYKS0Y3ZWowN2QwVDdaRDB1QXhJanhJaXp6aVpQblczeXpUakp6Z1F4NVVWbFBzcGovTURrU1FZdGV0K2NDMjhBcwpCZmRiTzc3VzBycHl5UHcwZUVSZDA5VzNEaGxnY2JONVBLTEt5Z1NHQitHMi9JYVNYK0dUbTd6d0xqbEIraHhzCmxlRG9HWkk0N1hBeFk4djFaVk1LbFZlTmVMaGZKdzNoc0xTOG5ONDRHSXVBaWlPM3djVUtJMm1COE1EZHljOGIKU3BYYStJUWc3a0VsCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K")
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args        = ["eks", "get-token", "--cluster-name", "eks-prod"]
#     }
#   }
# }