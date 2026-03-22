resource "aws_iam_role" "glue" {
  name = "aurora-poc-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_s3" {
  name = "aurora-poc-glue-s3-policy"
  role = aws_iam_role.glue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.glue_scripts.arn,
        "${aws_s3_bucket.glue_scripts.arn}/*"
      ]
    }]
  })
}

resource "aws_glue_catalog_database" "main" {
  name = "aurora-poc-db"
}

resource "aws_glue_connection" "aurora" {
  name            = "aurora-poc-connection"
  connection_type = "JDBC"

  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:mysql://${aws_rds_cluster.aurora.endpoint}:3306/testdb"
    USERNAME            = var.glue_db_username
    PASSWORD            = var.glue_db_password
  }

  physical_connection_requirements {
    availability_zone      = "${var.aws_region}a"
    security_group_id_list = [aws_security_group.glue.id]
    subnet_id              = aws_subnet.private_a.id
  }
}

resource "aws_glue_job" "insert_users" {
  name              = "aurora-poc-insert-users"
  role_arn          = aws_iam_role.glue.arn
  glue_version      = "5.0"
  worker_type       = "G.1X"
  number_of_workers = 2

  connections = [aws_glue_connection.aurora.name]

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.glue_scripts.bucket}/scripts/insert_users.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language" = "python"
    "--TempDir"      = "s3://${aws_s3_bucket.glue_scripts.bucket}/temp/"
    "--DB_URL"       = "jdbc:mysql://${aws_rds_cluster.aurora.endpoint}:3306/testdb"
    "--DB_USER"      = var.glue_db_username
    "--DB_PASSWORD"  = var.glue_db_password
  }
}

resource "aws_s3_bucket" "glue_scripts" {
  bucket        = "aurora-poc-glue-scripts-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

data "aws_caller_identity" "current" {}
