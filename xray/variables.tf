variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "reservoir_size" {
  description = "Fixed number of matching requests to trace each second before applying the sampling rate"
  type        = number
  default     = 1
}

variable "fixed_rate" {
  description = "Percentage of matching requests to trace after the reservoir is used"
  type        = number
  default     = 0.05
}
