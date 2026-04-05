output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.network.alb_dns_name
}

# output "github_connection_arn" {}
# output "pipeline_name" {}
# output "artifact_bucket_name" {}
