output "cluster-prod_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks-prod.cluster_endpoint
}

output "eks_cluster-prod_ca_cert" {
  value = module.eks-prod.cluster_certificate_authority_data
}

output "karpenter_node_role_name" {
  description = "Karpenter 노드 역할 이름"
  value       = module.eks-prod_blueprints_addons.karpenter.node_iam_role_name
}

output "oidc_provider_arn" {
  value = data.aws_iam_openid_connect_provider.oidc_provider.arn
}

output "bastionHost_sg_attachment" {
  description = "EKS cluster SG attached to ec2.bastionHost"
  value = module.eks-prod.cluster_primary_security_group_id
}