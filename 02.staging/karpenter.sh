#!/bin/bash

# Local variables
# CLUSTER_NAME="eks-staging-v2" # 클러스터 이름 변경!!
VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.resourcesVpcConfig.vpcId" --output text)
PRIVATE_SUBNETS=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=*private*" --query "Subnets[].SubnetId" --output text)
NODE_SG_ID=$(aws ec2 describe-security-groups \
  --filters \
  Name=vpc-id,Values=$VPC_ID \
  Name=tag:Name,Values=${CLUSTER_NAME}-node \
  --query "SecurityGroups[0].GroupId" \
  --output text)
KARPENTER_NAMESPACE="karpenter"
KARPENTER_VERSION="v0.37.0"
K8S_VERSION="1.31"
AWS_PARTITION="aws"
AWS_DEFAULT_REGION="ap-northeast-2"
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
TEMPOUT="$(mktemp)"
ARM_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2-arm64/recommended/image_id --query Parameter.Value --output text)"
AMD_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2/recommended/image_id --query Parameter.Value --output text)"
GPU_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2-gpu/recommended/image_id --query Parameter.Value --output text)"
KARPENTER_NODE_ROLE=$(aws iam list-roles --query "Roles[?starts_with(RoleName, \`karpenter-${CLUSTER_NAME}-\`)].RoleName" --output text | cut -d' ' -f1)
KARPENTER_NODE_ROLE_ARN=$(aws iam list-roles --query "Roles[?contains(RoleName, '$KARPENTER_NODE_ROLE') && contains(RoleName, '$CLUSTER_NAME')].Arn" --output text)

# TAG Subnets & Security Group
echo "Executing TAG Subnets & Security Group"

for SUBNET in $PRIVATE_SUBNETS
do
aws ec2 create-tags --resources $SUBNET --tags Key="karpenter.sh/discovery",Value="$CLUSTER_NAME"
done

aws ec2 create-tags --resources $NODE_SG_ID --tags Key="karpenter.sh/discovery",Value="$CLUSTER_NAME"

# MAKE EC2 Node Class & Node Pool
aws eks update-kubeconfig --name $CLUSTER_NAME
echo "Executing MAKE EC2 Node Class & Node Pool"
cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      requirements:
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot"]
        - key: karpenter.k8s.aws/instance-family
          operator: In
          values: ["t3", "c5", "m5"]
        - key: karpenter.k8s.aws/instance-size
          operator: In
          values: ["xlarge"]
      nodeClassRef:
        apiVersion: karpenter.k8s.aws/v1beta1
        kind: EC2NodeClass
        name: default
  limits:
    cpu: 1000
  disruption:
    consolidationPolicy: WhenUnderutilized
    expireAfter: 720h
---
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2
  role: "${KARPENTER_NODE_ROLE}"
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: "${CLUSTER_NAME}"
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: "${CLUSTER_NAME}"
  amiSelectorTerms:
    - id: "${AMD_AMI_ID}"
EOF

# EDIT Configmap aws-auth in kube-system Namespace
echo "Executing EDIT Configmap aws-auth in kube-system Namespace"

kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth-temp.yaml
sed -i "/mapRoles: |/a\    - groups:\n      - system:bootstrappers\n      - system:nodes\n      rolearn: $KARPENTER_NODE_ROLE_ARN\n      username: system:node:{{EC2PrivateDNSName}}" aws-auth-temp.yaml
kubectl apply -f aws-auth-temp.yaml
rm -rf aws-auth-temp.yaml

echo "All scripts executed successfully!"