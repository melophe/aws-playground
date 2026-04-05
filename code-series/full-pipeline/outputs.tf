output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.network.alb_dns_name
}

output "github_connection_arn" {
  description = "ARN of the CodeStar Connection (requires manual approval in console)"
  value       = module.github.connection_arn
}

output "github_connection_status" {
  description = "PENDING until manually approved in AWS console"
  value       = module.github.connection_status
}

# output "pipeline_name" {}
# output "artifact_bucket_name" {}
