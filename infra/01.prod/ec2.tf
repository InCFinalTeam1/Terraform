resource "aws_instance" "bh" {
  ami = var.bh-ami
  instance_market_options {
    market_type = "spot"
  }
  instance_type = "t2.micro"
  subnet_id = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.bh-sg.id]
  tags = {
    Name = "bastionHost"
  }
}

resource "aws_instance" "gitlab" {
  ami = var.gitlab-ami
  instance_market_options {
    market_type = "spot"
  }
  instance_type = "t3.large"
  subnet_id = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.gl-sg.id]
  tags = {
    Name = "gitlab"
  }
}

