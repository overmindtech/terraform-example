# This file contains resources that allow terraform running on GitHub Actions
# see https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services for details

provider "aws" {
  region = "us-east-1"
}

# Disable this temporarily during bootstrapping and use `terraform init
# -migrate-state` to migrate the local state into S3 after all resources have
# been deployed
terraform {
  backend "s3" {
    bucket         = "replaceme-with-a-unique-bucket-name"
    dynamodb_table = "overmind-tf-example-state"
    key            = "terraform-example.tfstate"

    region = "eu-west-2"
  }
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_s3_bucket" "terraform-example-state-bucket" {
  bucket = "replaceme-with-a-unique-bucket-name"
}

resource "aws_dynamodb_table" "terraform-example-lock-table" {
  name         = "overmind-tf-example-state"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "LockID"
    type = "S"
  }
  hash_key = "LockID"
}

resource "aws_iam_role" "deploy_role" {
  name        = "terraform-example"
  description = "This is the role used by terraform running on github actions to deploy."

  inline_policy {
    // this is required if any part of the deployment accesses public ECR resources
    name = "AllowPublicECR"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "ecr-public:GetAuthorizationToken",
            "sts:GetServiceBearerToken"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
  managed_policy_arns = [aws_iam_policy.state_access.arn, "arn:aws:iam::aws:policy/AdministratorAccess"]
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowGithubOIDC",
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:overmindtech/terraform-example:*"
          },
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# these permissions called out separately for hosting tfstate in a separate locked down account
resource "aws_iam_policy" "state_access" {
  name        = "TerraformStateAccess-terraform-example"
  path        = "/"
  description = "Allows access to everything terraform needs (state, lock, deploy role) to deploy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Deploy",
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
        ]
        Resource = "arn:aws:iam::${local.account_id}:role/terraform-example", # aws_iam_role.deploy_role.arn, except that it would create a dependency loop
      },
      {
        Sid    = "TFStateList",
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.terraform-example-state-bucket.arn,
      },
      {
        Sid    = "TFStateAccess",
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.terraform-example-state-bucket.arn}/terraform-example.tfstate",
      },
      {
        Sid    = "TFLock",
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/overmind-tf-example-state",
        Condition = {
          "ForAllValues:StringEquals" = {
            "dynamodb:LeadingKeys" = [
              "overmind-tf-example-state/terraform-example.tfstate",
              "overmind-tf-example-state/terraform-example.tfstate-md5"
            ]
          }
        }
      },
    ]
  })
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", ]
}
