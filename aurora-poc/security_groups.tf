# Bastion用SG（SSMなのでインバウンド22番不要）
resource "aws_security_group" "bastion" {
  name        = "aurora-poc-bastion-sg"
  description = "Security group for Bastion host"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "HTTPS for SSM"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "MySQL to Aurora"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name = "aurora-poc-bastion-sg"
  }
}

# Glue用SG
resource "aws_security_group" "glue" {
  name        = "aurora-poc-glue-sg"
  description = "Security group for Glue job"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Glue自己参照ルール（必須）
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  tags = {
    Name = "aurora-poc-glue-sg"
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

  ingress {
    description     = "MySQL from Glue"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.glue.id]
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
