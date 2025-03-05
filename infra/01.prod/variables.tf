variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "region" {
    type = string
    default = "ap-northeast-2"
}

variable "env" {
    type = string
    default = "prod"
}

variable "project_name" {
    type = string
    default = "finalpj"
}

variable "vpc_cidr" {
  description = "VPC-staging CIDR Block"
  type = string
  default = "10.0.0.0/16"
}

variable "az_count" {
  default = 4
}

variable "pri-subnet" {
  type = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
}
variable "pub-subnet" {
  type = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24", "10.0.104.0/24"]
}

variable "eks_name" {
  default = "eks"
  type    = string
}

variable "eks_version" {
  default = "1.31"
  type    = string
}

variable "AMZLX2_myRG" {
  type = string
  default = "ami-055811530249cf67e"
}

variable "bh-ami" {
  type = string
  default = "ami-0a3e00de3f673611d"
}

variable "gitlab-ami" {
  type = string
  default = "ami-0360f4782effd9054"
}