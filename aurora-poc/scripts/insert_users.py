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
