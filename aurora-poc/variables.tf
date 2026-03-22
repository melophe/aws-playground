variable "aws_region" {
  default = "ap-northeast-1"
}

variable "db_password" {
  description = "Aurora MySQL root password"
  type        = string
  sensitive   = true
}

variable "db_username" {
  default = "admin"
}

variable "db_name" {
  default = "testdb"
}

variable "github_repo" {
  description = "GitHub repository in format owner/repo"
  type        = string
}

variable "glue_db_username" {
  description = "Glue DB username"
  type        = string
  default     = "glue_user"
}

variable "glue_db_password" {
  description = "Glue DB password"
  type        = string
  sensitive   = true
}
