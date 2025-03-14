## iam.tf PART
# EKS 클러스터의 OIDC Provider URL 가져오기
data "aws_eks_cluster" "eks" {
  depends_on = [ module.eks-prod ]
  name = module.eks-prod.cluster_name
}

# OIDC Provider ARN 가져오기
data "aws_iam_openid_connect_provider" "oidc_provider" {
  url = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

# 클러스터 노드에 추가할 정책(EBS CNI Driver Policy)
data "aws_iam_policy" "ebs_cni_policy" {
  name = "AmazonEBSCSIDriverPolicy"
}
