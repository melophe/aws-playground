resource "aws_apigatewayv2_api" "main" {
  name                         = "cognito-handson-api"
  protocol_type                = "HTTP"
  api_key_selection_expression = "$request.header.x-api-key"
  route_selection_expression   = "$request.method $request.path"
  disable_execute_api_endpoint = false
  ip_address_type              = "ipv4"
}

resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id                            = aws_apigatewayv2_api.main.id
  authorizer_type                   = "JWT"
  identity_sources                  = ["$request.header.Authorization"]
  name                              = "cognito-authorizer"
  authorizer_result_ttl_in_seconds  = 0
  enable_simple_responses           = false

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.main.id]
    issuer   = "https://cognito-idp.ap-northeast-1.amazonaws.com/${aws_cognito_user_pool.main.id}"
  }
}
