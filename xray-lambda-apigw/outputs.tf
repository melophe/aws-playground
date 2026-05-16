output "api_endpoint" {
  description = "API Gateway endpoint for the traced Lambda"
  value       = "${aws_api_gateway_stage.dev.invoke_url}/hello"
}

output "lambda_function_name" {
  description = "Lambda function with active tracing enabled"
  value       = aws_lambda_function.hello.function_name
}

output "api_gateway_stage_name" {
  description = "API Gateway stage with X-Ray tracing enabled"
  value       = aws_api_gateway_stage.dev.stage_name
}
