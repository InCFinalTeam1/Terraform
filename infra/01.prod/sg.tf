resource "aws_security_group" "bh-sg" {
  name        = "bh-sg"
  description = "Bastion Host SG"
  vpc_id      = module.vpc.vpc_id 

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bh-sg"
  }
}

resource "aws_security_group" "gl-sg" {
  depends_on = [ aws_security_group.bh-sg ]

  name        = "gl-sg"
  description = "GitLab SG"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port                = 9000
    to_port                  = 9000
    protocol                 = "tcp"
    security_groups          = [aws_security_group.bh-sg.id] 
  }

  ingress {
    from_port                = 80
    to_port                  = 80
    protocol                 = "tcp"
    security_groups          = [aws_security_group.bh-sg.id]
  }

  ingress {
    from_port                = 443
    to_port                  = 443
    protocol                 = "tcp"
    security_groups          = [aws_security_group.bh-sg.id]
  }

  ingress {
    from_port                = 22
    to_port                  = 22
    protocol                 = "tcp"
    security_groups          = [aws_security_group.bh-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "gl-sg"
  }
}

resource "aws_security_group_rule" "new-gl-sg-rule" {
  depends_on = [ aws_security_group.gl-sg, module.eks-prod ]
  security_group_id = aws_security_group.gl-sg.id 

  type              = "ingress"
  from_port         = 80
  to_port           = 80  
  protocol          = "tcp"
  source_security_group_id = module.eks-prod.node_security_group_id
  
  description = "gitlab-eksNode-80/tcp"
}

output "new-gl-sg-rule_sourceSG" {
  description = "source SG of new gitLab sg-rule"
  value = module.eks-prod.cluster_primary_security_group_id
}

resource "aws_network_interface_sg_attachment" "bh-sg-attachment" {
  security_group_id    = module.eks-prod.cluster_primary_security_group_id
  network_interface_id = aws_instance.bh.primary_network_interface_id
}



# EKS Node SG: ingress 15017/tcp source:vpc's CIDR 추가
resource "aws_security_group_rule" "new-eksnode-sg-rule" {
  type              = "ingress"
  from_port         = 15017
  to_port           = 15017
  protocol          = "tcp"
  cidr_blocks       = [module.vpc.vpc_cidr_block]
  security_group_id = module.eks-prod.node_security_group_id 
  
  description = "gitlab-eksNode-80/tcp"
}
