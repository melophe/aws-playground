resource "aws_db_subnet_group" "aurora" {
  name       = "aurora-poc-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_c.id]

  tags = {
    Name = "aurora-poc-subnet-group"
  }
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = "aurora-poc-cluster"
  engine                  = "aurora-mysql"
  engine_version          = "8.0.mysql_aurora.3.05.2"
  database_name           = var.db_name
  master_username         = var.db_username
  master_password         = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.aurora.name
  vpc_security_group_ids  = [aws_security_group.aurora.id]
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = {
    Name = "aurora-poc-cluster"
  }
}

resource "aws_rds_cluster_instance" "aurora" {
  identifier         = "aurora-poc-instance"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version

  tags = {
    Name = "aurora-poc-instance"
  }
}
