# terraform_finalpj
```
$ tree terraform
terraform
|-- 00.terraform-backend
|   |-- backend.tf
|   |-- outputs.tf
|   |-- provider.tf
|   |-- terraform.tfstate
|   |-- terraform.tfstate.backup
|   |-- terraform.tfvars
|   `-- variables.tf
|-- 01.prod
|   |-- data.tf
|   |-- ec2.tf
|   |-- eks-addons.tf
|   |-- eks.tf
|   |-- errored.tfstate
|   |-- iam.tf
|   |-- output.tf
|   |-- provider.tf
|   |-- sg.tf
|   |-- terraform.tfvars
|   |-- variables.tf
|   |-- version.tf
|   `-- vpc.tf
|-- 02.staging
|   |-- eks.tf
|   |-- errored.tfstate
|   |-- iam.tf
|   |-- karpenter.sh
|   |-- provider.tf
|   |-- terraform.tfvars
|   |-- variables.tf
|   `-- vpc.tf
|-- 03.QA
|   |-- eks.tf
|   |-- provider.tf
|   |-- terraform.tfvars
|   |-- variables.tf
|   `-- vpc.tf
|-- 10.common
|   |-- athena
|   |-- dynamodb
|   |-- kinesis
|   |-- lambda
|   `-- s3
`-- README.md
```
