provider "aws" {
    profile = "default"
    region = "ap-southeast-2"
}
// Website runs on amplify. no provider module yet :(

variable account_id {
  type=string
  default="417748018202"
}
variable myregion {
  type=string
  default="ap-southeast-2"
}

resource "aws_cognito_user_pool" "pool" {
  name = "WyldRydes"
  password_policy {
    minimum_length = 6
    require_lowercase =  false
    require_numbers = false
    require_symbols = false
    require_uppercase = false
    temporary_password_validity_days = 7
  }
}

resource "aws_cognito_user_pool_client" "client" {
    name = "WyldRydesWebApp"
    user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_dynamodb_table" "table" {
  name = "Rides"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "RideId"

  attribute {
    name = "RideId"
    type = "S"
  }
}

resource "aws_lambda_function" "lambda" {
  filename = "request_unicorn.js.zip"
  function_name = "RequestUnicorn"
  runtime = "nodejs12.x"
  role = "arn:aws:iam::417748018202:role/WildRydesLambda"
  handler = "request_unicorn.handler"
}

resource "aws_api_gateway_rest_api" "api" {
  name = "WildRydes"
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "resource"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.myregion}:${var.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
}