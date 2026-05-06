# This file contains resources that allow terraform running on GitHub Actions
# see https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services for details

provider "aws" {
  region = "eu-west-2"
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
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
      version = "< 6.38"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
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
# Inline policy for public ECR access (moved from deprecated inline_policy block)
resource "aws_iam_role_policy" "allow_public_ecr" {
  name = "AllowPublicECR"
  role = aws_iam_role.deploy_role.id

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

# Managed policy attachments (moved from deprecated managed_policy_arns)
resource "aws_iam_role_policy_attachment" "state_access" {
  role       = aws_iam_role.deploy_role.name
  policy_arn = aws_iam_policy.state_access.arn
}

resource "aws_iam_role_policy_attachment" "administrator_access" {
  role       = aws_iam_role.deploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Ensure Terraform exclusively manages all managed policy attachments
resource "aws_iam_role_policy_attachments_exclusive" "deploy_role" {
  role_name = aws_iam_role.deploy_role.name
  policy_arns = [
    aws_iam_policy.state_access.arn,
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]
}

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

# =============================================================================
# GCP Workload Identity Federation
# Mirrors the AWS OIDC provider + deploy role pattern above.
# See https://cloud.google.com/iam/docs/workload-identity-federation
# =============================================================================

# Needed to construct the env0 GCP OIDC credential JSON (audience URL uses the
# project *number*, not the project id).
data "google_project" "current" {
  project_id = var.gcp_project_id
}

resource "google_iam_workload_identity_pool" "deploy" {
  workload_identity_pool_id = "${var.example_env}-deploy"
  display_name              = "Deploy Pool (${var.example_env})"
  description               = "Workload Identity Pool for CI/CD platforms to deploy infrastructure"
}

# GitHub Actions OIDC provider
resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.deploy.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions"
  display_name                       = "GitHub Actions"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == 'overmindtech/terraform-example'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Terraform Cloud OIDC provider
resource "google_iam_workload_identity_pool_provider" "tfc" {
  count = var.example_env == "terraform-example" ? 1 : 0

  workload_identity_pool_id          = google_iam_workload_identity_pool.deploy.workload_identity_pool_id
  workload_identity_pool_provider_id = "terraform-cloud"
  display_name                       = "Terraform Cloud"

  attribute_mapping = {
    "google.subject"                   = "assertion.sub"
    "attribute.terraform_workspace"    = "assertion.terraform_workspace_name"
    "attribute.terraform_organization" = "assertion.terraform_organization_name"
  }

  attribute_condition = "assertion.terraform_organization_name == 'Overmind'"

  oidc {
    issuer_uri        = "https://app.terraform.io"
    allowed_audiences = ["gcp.workload.identity"]
  }
}

# env0 OIDC provider
resource "google_iam_workload_identity_pool_provider" "env0" {
  count = var.example_env == "terraform-example" ? 1 : 0

  workload_identity_pool_id          = google_iam_workload_identity_pool.deploy.workload_identity_pool_id
  workload_identity_pool_provider_id = "env0"
  display_name                       = "env0"

  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }

  oidc {
    issuer_uri        = "https://login.app.env0.com/"
    allowed_audiences = ["https://prod.env0.com"]
  }
}

# Spacelift OIDC provider
resource "google_iam_workload_identity_pool_provider" "spacelift" {
  count = var.example_env == "terraform-example" ? 1 : 0

  workload_identity_pool_id          = google_iam_workload_identity_pool.deploy.workload_identity_pool_id
  workload_identity_pool_provider_id = "spacelift"
  display_name                       = "Spacelift"

  attribute_mapping = {
    "google.subject"        = "assertion.sub"
    "attribute.space"       = "assertion.spaceId"
    "attribute.stack"       = "assertion.callerId"
    "attribute.caller_type" = "assertion.callerType"
  }

  oidc {
    issuer_uri = "https://overmindtech.app.spacelift.io"
  }
}

# Deploy service account (GCP equivalent of aws_iam_role.deploy_role)
resource "google_service_account" "deploy" {
  account_id   = "${var.example_env}-deploy"
  display_name = "Terraform Deploy (${var.example_env})"
  description  = "Service account used by CI/CD platforms to deploy infrastructure via Workload Identity Federation"
}

resource "google_project_iam_member" "deploy_editor" {
  project = var.gcp_project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.deploy.email}"
}

# Allow the Workload Identity Pool to impersonate the deploy service account
resource "google_service_account_iam_member" "github_wif" {
  service_account_id = google_service_account.deploy.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.deploy.name}/attribute.repository/overmindtech/terraform-example"
}

resource "google_service_account_iam_member" "tfc_wif" {
  count = var.example_env == "terraform-example" ? 1 : 0

  service_account_id = google_service_account.deploy.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.deploy.name}/attribute.terraform_organization/Overmind"
}

resource "google_service_account_iam_member" "env0_wif" {
  count = var.example_env == "terraform-example" ? 1 : 0

  service_account_id = google_service_account.deploy.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.deploy.name}/subject/auth0|691b8530eba074a8989d8726"
}

resource "google_service_account_iam_member" "spacelift_wif" {
  count = var.example_env == "terraform-example" ? 1 : 0

  service_account_id = google_service_account.deploy.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.deploy.name}/*"
  condition {
    title      = "spacelift-provider-only"
    expression = "request.auth.claims.iss == 'https://overmindtech.app.spacelift.io'"
  }
}
