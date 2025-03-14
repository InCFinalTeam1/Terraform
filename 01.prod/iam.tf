# EKS Node& Karpenter Node IAM 역할에 AmazonEBSCSIDriverPolicy 정책 추가

resource "aws_iam_role_policy_attachment" "system_nodegroup_ebs_cni_policy" {
  depends_on = [ module.eks-prod ]
  policy_arn = data.aws_iam_policy.ebs_cni_policy.arn
  role       = module.eks-prod.eks_managed_node_groups["system"].iam_role_name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ebs_cni_policy" {
  depends_on = [ module.eks-prod ]
  policy_arn = data.aws_iam_policy.ebs_cni_policy.arn
  role       = module.eks-prod_blueprints_addons.karpenter.node_iam_role_name
}

### IRSA PART

## eks-pod-app-role 생성
# 파드에 필요한 정책 생성
resource "aws_iam_policy" "eks_pod_policy" {
  name        = "eks-pod-policy"
  description = "Policy for EKS Pods with permissions to access S3, Lambda, DynamoDB, Kinesis, ElastiCache, and API Gateway"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "VisualEditor0"
        Effect = "Allow"
        Action = [
          "s3:*",
          "lambda:*",
          "dynamodb:*",
          "kinesis:*",
          "apigateway:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# 만든 정책 붙여서 역할 생성
resource "aws_iam_role" "eks_pod_role" {
  name               = "eks-pod-app-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.oidc_provider.arn
        }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${trimprefix(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_pod_policy_attach" {
  role       = aws_iam_role.eks_pod_role.name
  policy_arn = aws_iam_policy.eks_pod_policy.arn
}

# for Streamlit Pods' sa
resource "aws_iam_role" "eks_dynamodb_reader" {
  name = "eks-dynamodb-reader"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.oidc_provider.arn
        }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${trimprefix(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# AmazonDynamoDBReadOnlyAccess 정책 부착
resource "aws_iam_role_policy_attachment" "dynamodb_read_only" {
  role       = aws_iam_role.eks_dynamodb_reader.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
}