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

resource "aws_glue_catalog_database" "main" {
  name = "aurora-poc-db"
}

resource "aws_glue_connection" "aurora" {
  name            = "aurora-poc-connection"
  connection_type = "JDBC"

  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:mysql://${aws_rds_cluster.aurora.endpoint}:3306/testdb"
    USERNAME            = "glue_user"
    PASSWORD            = "***REMOVED***"
  }

  physical_connection_requirements {
    availability_zone      = "${var.aws_region}a"
    security_group_id_list = [aws_security_group.glue.id]
    subnet_id              = aws_subnet.private_a.id
  }
}

resource "aws_glue_job" "insert_users" {
  name         = "aurora-poc-insert-users"
  role_arn     = aws_iam_role.glue.arn
  glue_version = "4.0"

  connections = [aws_glue_connection.aurora.name]

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.glue_scripts.bucket}/scripts/insert_users.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"        = "python"
    "--TempDir"             = "s3://${aws_s3_bucket.glue_scripts.bucket}/temp/"
    "--DB_URL"              = "jdbc:mysql://${aws_rds_cluster.aurora.endpoint}:3306/testdb"
    "--DB_USER"             = "glue_user"
    "--DB_PASSWORD"         = "***REMOVED***"
  }
}

resource "aws_s3_bucket" "glue_scripts" {
  bucket        = "aurora-poc-glue-scripts-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

data "aws_caller_identity" "current" {}

resource "aws_s3_object" "insert_users_script" {
  bucket  = aws_s3_bucket.glue_scripts.bucket
  key     = "scripts/insert_users.py"
  content = <<-EOF
import sys
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

args = getResolvedOptions(sys.argv, ['JOB_NAME', 'DB_URL', 'DB_USER', 'DB_PASSWORD'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# 挿入するデータ
data = [
    (1, "Alice", "alice@example.com"),
    (2, "Bob",   "bob@example.com"),
    (3, "Carol", "carol@example.com"),
]
columns = ["id", "name", "email"]
df = spark.createDataFrame(data, columns)

# Auroraに書き込み
df.write \
    .format("jdbc") \
    .option("url", args['DB_URL']) \
    .option("dbtable", "users") \
    .option("user", args['DB_USER']) \
    .option("password", args['DB_PASSWORD']) \
    .option("driver", "com.mysql.cj.jdbc.Driver") \
    .mode("append") \
    .save()

job.commit()
EOF
}
