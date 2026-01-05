# =============================================================================
# Terraform Backend Configuration
# Scale Testing Infrastructure for Overmind
# =============================================================================
# Uses S3 for state storage with DynamoDB for locking.
# Ensure the bucket and table exist before running terraform init.
# =============================================================================

# =============================================================================
# S3 Backend (for production use)
# =============================================================================
# Uncomment this block and comment out the local backend below for production.
#
# terraform {
#   backend "s3" {
#     bucket         = "overmind-scale-test-tfstate"
#     key            = "scale-test/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "overmind-scale-test-tfstate-lock"
#
#     # Uncomment if using AWS SSO or assume role
#     # role_arn = "arn:aws:iam::ACCOUNT_ID:role/TerraformStateAccess"
#   }
# }

# =============================================================================
# Local Backend (for development/validation)
# =============================================================================
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
# =============================================================================

