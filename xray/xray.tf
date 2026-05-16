resource "aws_xray_sampling_rule" "api_errors" {
  rule_name      = "${var.env}-api-errors"
  priority       = 1000
  version        = 1
  reservoir_size = var.reservoir_size
  fixed_rate     = var.fixed_rate
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"

  attributes = {
    Environment = var.env
  }
}

resource "aws_xray_group" "api_errors" {
  group_name        = "${var.env}-api-errors"
  filter_expression = "fault = true OR error = true OR throttle = true"

  insights_configuration {
    insights_enabled      = true
    notifications_enabled = false
  }
}
