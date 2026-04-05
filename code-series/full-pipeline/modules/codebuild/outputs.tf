output "project_name" { value = aws_codebuild_project.app.name }
output "artifact_bucket_name" { value = aws_s3_bucket.artifact.id }
output "artifact_bucket_arn" { value = aws_s3_bucket.artifact.arn }
