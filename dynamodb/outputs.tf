output "orders_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.orders.name
}

output "orders_table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.orders.arn
}
