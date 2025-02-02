terraform {
  required_version = ">= 1.0"
}
provider "aws" {
  region = var.region
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}