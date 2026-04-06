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
# CloudWatch Logs (Lambda)
# ----------------------------------------
resource "aws_cloudwatch_log_group" "lambda_items" {
  name              = "/aws/lambda/my-lambda-items"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "lambda_health" {
  name              = "/aws/lambda/my-lambda-health"
  retention_in_days = 14
}

# ----------------------------------------
# Lambda Layer
# ----------------------------------------
data "archive_file" "layer" {
  type        = "zip"
  source_dir  = "${path.module}/layer"
  output_path = "${path.module}/dist/layer.zip"
}

resource "aws_lambda_layer_version" "common" {
  layer_name          = "common-libs"
  filename            = data.archive_file.layer.output_path
  source_code_hash    = data.archive_file.layer.output_base64sha256
  compatible_runtimes = ["python3.12"]
}

# ----------------------------------------
# Lambda Functions
# ----------------------------------------
data "archive_file" "lambda_items" {
  type        = "zip"
  source_file = "${path.module}/src/index.py"
  output_path = "${path.module}/dist/lambda-items.zip"
}

data "archive_file" "lambda_health" {
  type        = "zip"
  source_file = "${path.module}/src/health.py"
  output_path = "${path.module}/dist/lambda-health.zip"
}

resource "aws_lambda_function" "items" {
  function_name    = "my-lambda-items"
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda_items.output_path
  source_code_hash = data.archive_file.lambda_items.output_base64sha256
  publish          = true
  layers           = [aws_lambda_layer_version.common.arn]

  environment {
    variables = {
      ENV = "dev"
    }
  }
}

resource "aws_lambda_function" "health" {
  function_name    = "my-lambda-health"
  role             = aws_iam_role.lambda.arn
  handler          = "health.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda_health.output_path
  source_code_hash = data.archive_file.lambda_health.output_base64sha256
  publish          = true
  layers           = [aws_lambda_layer_version.common.arn]

  environment {
    variables = {
      ENV = "dev"
    }
  }
}

resource "aws_lambda_alias" "items_live" {
  name             = "live"
  function_name    = aws_lambda_function.items.function_name
  function_version = aws_lambda_function.items.version

  routing_config {
    additional_version_weights = {}
  }
}

resource "aws_lambda_alias" "health_live" {
  name             = "live"
  function_name    = aws_lambda_function.health.function_name
  function_version = aws_lambda_function.health.version

  routing_config {
    additional_version_weights = {}
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

resource "aws_apigatewayv2_integration" "items" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_alias.items_live.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "health" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_alias.health_live.invoke_arn
  payload_format_version = "2.0"
}

# GET /items
resource "aws_apigatewayv2_route" "get_items" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /items"
  target    = "integrations/${aws_apigatewayv2_integration.items.id}"
}

# POST /items
resource "aws_apigatewayv2_route" "post_items" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /items"
  target    = "integrations/${aws_apigatewayv2_integration.items.id}"
}

# GET /health
resource "aws_apigatewayv2_route" "get_health" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.health.id}"
}

resource "aws_lambda_permission" "apigw_items" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.items.function_name
  qualifier     = aws_lambda_alias.items_live.name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_health" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health.function_name
  qualifier     = aws_lambda_alias.health_live.name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# ----------------------------------------
# Outputs
# ----------------------------------------
output "api_endpoint" {
  value = aws_apigatewayv2_api.main.api_endpoint
}

output "lambda_function_names" {
  value = {
    items  = aws_lambda_function.items.function_name
    health = aws_lambda_function.health.function_name
  }
}
