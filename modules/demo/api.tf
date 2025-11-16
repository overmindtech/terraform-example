resource "aws_apigatewayv2_api" "recipes" {
  name          = "${local.name_prefix}-api"
  protocol_type = "HTTP"
  tags          = local.tags
}

resource "aws_apigatewayv2_integration" "recipes" {
  api_id                 = aws_apigatewayv2_api.recipes.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "presign" {
  api_id                 = aws_apigatewayv2_api.recipes.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.presign.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_authorizer" "recipes" {
  api_id                            = aws_apigatewayv2_api.recipes.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.authorizer.invoke_arn
  authorizer_payload_format_version = "2.0"
  identity_sources                  = ["$request.header.Authorization"]
  name                              = "${local.name_prefix}-authorizer"
}

resource "aws_apigatewayv2_route" "recipes_get" {
  api_id    = aws_apigatewayv2_api.recipes.id
  route_key = "GET /api/recipes"

  target             = "integrations/${aws_apigatewayv2_integration.recipes.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.recipes.id
  authorization_type = "CUSTOM"
}

resource "aws_apigatewayv2_route" "recipes_post" {
  api_id    = aws_apigatewayv2_api.recipes.id
  route_key = "POST /api/recipes"

  target             = "integrations/${aws_apigatewayv2_integration.recipes.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.recipes.id
  authorization_type = "CUSTOM"
}

resource "aws_apigatewayv2_route" "presign" {
  api_id    = aws_apigatewayv2_api.recipes.id
  route_key = "POST /api/uploads/presign"

  target             = "integrations/${aws_apigatewayv2_integration.presign.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.recipes.id
  authorization_type = "CUSTOM"
}

resource "aws_apigatewayv2_stage" "recipes" {
  api_id      = aws_apigatewayv2_api.recipes.id
  name        = "$default"
  auto_deploy = true

  tags = local.tags
}

resource "aws_lambda_permission" "api_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.recipes.execution_arn}/*/*"
}

resource "aws_lambda_permission" "presign_invoke" {
  statement_id  = "AllowAPIGatewayPresign"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.presign.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.recipes.execution_arn}/*/*"
}

resource "aws_lambda_permission" "authorizer_invoke" {
  statement_id  = "AllowAPIAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = aws_apigatewayv2_api.recipes.execution_arn
}

