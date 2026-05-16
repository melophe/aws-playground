output "xray_sampling_rule_name" {
  description = "X-Ray sampling rule name"
  value       = aws_xray_sampling_rule.api_errors.rule_name
}

output "xray_group_name" {
  description = "X-Ray group name"
  value       = aws_xray_group.api_errors.group_name
}

output "xray_group_arn" {
  description = "X-Ray group ARN"
  value       = aws_xray_group.api_errors.arn
}
