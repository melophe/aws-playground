# Bastion用SG
resource "aws_security_group" "bastion" {
  name        = "aurora-poc-bastion-sg"
  description = "Security group for Bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aurora-poc-bastion-sg"
  }
}

# Aurora用SG
resource "aws_security_group" "aurora" {
  name        = "aurora-poc-aurora-sg"
  description = "Security group for Aurora MySQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from Bastion"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aurora-poc-aurora-sg"
  }
}
