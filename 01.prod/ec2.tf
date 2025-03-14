resource "aws_instance" "bh" {
  depends_on = [ module.eks-prod ]
  ami = var.bh-ami
  # instance_market_options {
  #   market_type = "spot"
  # }
  instance_type = "t3.micro"
  subnet_id = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.bh-sg.id, module.eks-prod.cluster_primary_security_group_id]
  tags = {
    Name = "bastionHost"
  }
}

resource "aws_instance" "gitlab" {
  ami = var.gitlab-ami
  # instance_market_options {
  #   market_type = "spot"
  # }
  private_ip = "10.0.1.80"
  instance_type = "t3.xlarge"
  subnet_id = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.gl-sg.id]
  tags = {
    Name = "gitLab"
  }
}