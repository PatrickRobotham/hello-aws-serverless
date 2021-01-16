provider "aws" {
    profile = "default"
    region = "ap-southeast-2"
}
// Website runs on amplify. no provider module yet :(

resource "aws_cognito_user_pool" "pool" {
  name = "WyldRydes"
}

resource "aws_cognito_user_pool_client" "client" {
    name = "WyldRydesWebApp"
    user_pool_id = aws_cognito_user_pool.pool.id
}