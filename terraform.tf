# This file contains resources that allow terraform running on GitHub Actions
# see https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services for details

provider "aws" {
  region = "eu-west-2"
}

# Disable this temporarily during bootstrapping and use `terraform init
# -migrate-state` to migrate the local state into S3 after all resources have
# been deployed
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # version 6 is breaking change across multiple AWS module # versions, so we pin to < 6.0 see https://github.com/terraform-aws-modules/terraform-aws-ecs/issues/291
      # another pin was added to modules/scenarios/main.tf for the VPC module
      # we expect this to be fixed over the coming weeks, as of 23/6/2025
      version = "< 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
  backend "s3" {
    # note that this configuration is only used on the github actions demo
    # example. HCP Terraform ignores this.
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
  bucket = var.example_env == "terraform-example" ? "replaceme-with-a-unique-bucket-name" : "7f8e2ff0-5018-11ef-97d9-2795780b78ce"
}

resource "aws_dynamodb_table" "terraform-example-lock-table" {
  name         = var.example_env == "terraform-example" ? "overmind-tf-example-state" : "8919e910-5018-11ef-bfa0-87fc68fc8aa5"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "LockID"
    type = "S"
  }
  hash_key = "LockID"
}

resource "aws_iam_role" "deploy_role" {
  name                 = var.example_env
  description          = "This is the role used by terraform running on github actions or Terraform Cloud to deploy."
  max_session_duration = 3600

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
    # Ensure that there is a valid federated principal, even on the non-default environments
    Statement = var.example_env == "terraform-example" ? tolist([
      {
        Sid    = "AllowGithubOIDC",
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        Action = ["sts:AssumeRoleWithWebIdentity"]
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:overmindtech/terraform-example:*"
          },
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      },
      {
        Sid    = "AllowTerraformOIDC",
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.tfc_provider[0].arn
        },
        Action = ["sts:AssumeRoleWithWebIdentity"]
        Condition = {
          StringLike = {
            "app.terraform.io:sub" = "organization:Overmind:project:Example:workspace:terraform-example:run_phase:*"
          },
          StringEquals = {
            "app.terraform.io:aud" = "aws.workload.identity"
          }
        }
      },
      {
        Sid    = "AllowEnv0OIDC",
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.env0[0].arn
        },
        Action = [
          "sts:AssumeRoleWithWebIdentity",
          "sts:TagSession",
        ]
        Condition = {
          StringEquals = {
            "login.app.env0.com/:aud" = "hoMiq9PdkRh9LUvVpH4wIErWg50VSG1b",
            "login.app.env0.com/:sub" = "auth0|691b8530eba074a8989d8726"
          }
        }
      },
      {
        Sid    = "AllowSpacelift",
        Effect = "Allow",
        Principal = {
          AWS = "324880187172"
        },
        Action = ["sts:AssumeRole"],
        Condition = {
          StringLike = {
            "sts:ExternalId" = "overmind-demo@*"
          }
        }
      }
      ]) : tolist([
      {
        Sid    = "AllowGithubOIDC",
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        Action = ["sts:AssumeRoleWithWebIdentity"]
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:overmindtech/terraform-example:*"
          },
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ])
  })
}

# these permissions called out separately for hosting tfstate in a separate locked down account
resource "aws_iam_policy" "state_access" {
  name        = "TerraformStateAccess-${var.example_env}"
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
        Resource = "arn:aws:iam::${local.account_id}:role/${var.example_env}", # aws_iam_role.deploy_role.arn, except that it would create a dependency loop
      },
      {
        Sid    = "TFStateList",
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetEncryptionConfiguration"
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
        # Grant access to all state files in the bucket
        # This allows access to any workspace state files stored in the bucket
        Resource = "${aws_s3_bucket.terraform-example-state-bucket.arn}/*"
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
              # Lock key for "terraform-example" workspace
              # Use: terraform workspace select terraform-example (both locally and in Env0)
              "replaceme-with-a-unique-bucket-name/env:/terraform-example/terraform-example.tfstate",
              "replaceme-with-a-unique-bucket-name/env:/terraform-example/terraform-example.tfstate-md5"
            ]
          }
        }
      },
    ]
  })
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.example_env == "terraform-example" ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", ]
}

# Data source used to grab the TLS certificate for Terraform Cloud.
#
# https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate
data "tls_certificate" "tfc_certificate" {
  url = "https://app.terraform.io"
}

data "tls_certificate" "env0" {
  url = "https://login.app.env0.com"
}

# Creates an OIDC provider which is restricted to
#
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider
resource "aws_iam_openid_connect_provider" "tfc_provider" {
  count           = var.example_env == "terraform-example" ? 1 : 0
  url             = data.tls_certificate.tfc_certificate.url
  client_id_list  = ["aws.workload.identity"]
  thumbprint_list = [data.tls_certificate.tfc_certificate.certificates[0].sha1_fingerprint]
}

resource "aws_iam_openid_connect_provider" "env0" {
  count           = var.example_env == "terraform-example" ? 1 : 0
  url             = "https://login.app.env0.com/"
  client_id_list  = ["hoMiq9PdkRh9LUvVpH4wIErWg50VSG1b"]
  thumbprint_list = [data.tls_certificate.env0.certificates[0].sha1_fingerprint]
}
