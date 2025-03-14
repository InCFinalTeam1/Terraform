terraform {
  required_version = ">= 1.0"
  backend "s3" {
   bucket = "terraform-state-finalproject"
   key = "qa/terraform.tfstate"
   region = "ap-northeast-2"
   dynamodb_table = "terraform-locks"
   encrypt = true
  }
}

provider "aws" {
  region = var.region
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}

