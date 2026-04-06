terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

# ----------------------------------------
# IAM Role
# ----------------------------------------
resource "aws_iam_role" "lambda" {
  name = "lambda-apigw-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ----------------------------------------
# CloudWatch Logs
# ----------------------------------------
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.main.function_name}"
  retention_in_days = 14
}

# ----------------------------------------
# Lambda Function
# ----------------------------------------
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/src/index.js"
  output_path = "${path.module}/dist/lambda.zip"
}

resource "aws_lambda_function" "main" {
  function_name    = "my-lambda"
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      ENV = "dev"
    }
  }
}

# ----------------------------------------
# API Gateway (HTTP API v2)
# ----------------------------------------
resource "aws_apigatewayv2_api" "main" {
  name          = "my-http-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE"]
    allow_headers = ["Content-Type", "Authorization"]
    max_age       = 300
  }
}


resource "aws_cloudwatch_log_group" "apigw" {
  for_each          = local.stages
  name              = "/aws/apigateway/${aws_apigatewayv2_api.main.name}/${each.key}"
  retention_in_days = 14
}

resource "aws_apigatewayv2_stage" "main" {
  for_each    = local.stages
  api_id      = aws_apigatewayv2_api.main.id
  name        = each.key
  auto_deploy = true

  default_route_settings {
    throttling_rate_limit  = each.value.throttling_rate_limit
    throttling_burst_limit = each.value.throttling_burst_limit
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw[each.key].arn
    format = jsonencode({
      requestId        = "$context.requestId"
      ip               = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      routeKey         = "$context.routeKey"
      status           = "$context.status"
      responseLength   = "$context.responseLength"
      integrationError = "$context.integrationErrorMessage"
    })
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.main.invoke_arn
  payload_format_version = "2.0"
}

# GET /items
resource "aws_apigatewayv2_route" "get_items" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /items"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# POST /items
resource "aws_apigatewayv2_route" "post_items" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /items"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Lambda に API Gateway からの呼び出しを許可
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# ----------------------------------------
# Outputs
# ----------------------------------------
output "api_endpoints" {
  value = {
    for stage, _ in local.stages :
    stage => "${aws_apigatewayv2_api.main.api_endpoint}/${stage}"
  }
}

output "lambda_function_name" {
  value = aws_lambda_function.main.function_name
}
