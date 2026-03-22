variable "aws_region" {
  default = "ap-northeast-1"
}

variable "my_ip" {
  description = "Your local IP address for Bastion SSH access (e.g. 1.2.3.4/32)"
  type        = string
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

