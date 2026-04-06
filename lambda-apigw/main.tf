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
  publish          = true

  environment {
    variables = {
      ENV = "dev"
    }
  }
}

resource "aws_lambda_alias" "live" {
  name             = "live"
  function_name    = aws_lambda_function.main.function_name
  function_version = aws_lambda_function.main.version

  routing_config {
    additional_version_weights = {
      # カナリアリリース時にここ変える
      # 例: "${aws_lambda_function.main.version}" = 0.1
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
  name              = "/aws/apigateway/${aws_apigatewayv2_api.main.name}"
  retention_in_days = 14
}

resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw.arn
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
  integration_uri        = aws_lambda_alias.live.invoke_arn
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
  qualifier     = aws_lambda_alias.live.name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# ----------------------------------------
# Outputs
# ----------------------------------------
output "api_endpoint" {
  value = aws_apigatewayv2_api.main.api_endpoint
}

output "lambda_function_name" {
  value = aws_lambda_function.main.function_name
}
