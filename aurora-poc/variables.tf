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
