variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "region" {
    type = string
    default = "ap-northeast-2"
}

variable "env" {
    type = string
    default = "qa"
}

variable "project_name" {
    type = string
    default = "finalpj"
}

variable "vpc_cidr" {
  description = "VPC-staging CIDR Block"
  type = string
  default = "10.2.0.0/16"
}

variable "az_count" {
  default = 4
}

variable "pri-subnet" {
  type = list(string)
  default = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24", "10.2.4.0/24"]
}
variable "pub-subnet" {
  type = list(string)
  default = ["10.2.101.0/24", "10.2.102.0/24", "10.2.103.0/24", "10.2.104.0/24"]
}

variable "AMZLX2_myRG" {
    type = string
    default = "ami-055811530249cf67e"
}

variable "eks_name" {
  default = "eks"
  type    = string
}

variable "eks_version" {
  default = "1.31"
  type    = string
}