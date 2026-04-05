variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Project name used as a prefix for resource names"
  type        = string
  default     = "code-series"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# variable "github_repo_url" {}
# variable "github_repo_id" {}
# variable "github_branch" {}
# variable "ssh_public_key" {}
# variable "approval_email" {}
