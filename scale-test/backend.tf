# =============================================================================
# Terraform Backend Configuration
# Scale Testing Infrastructure for Overmind
# =============================================================================
# Uses S3 for state storage with DynamoDB for locking.
# Bucket: overmind-scale-test-tfstate
# DynamoDB: overmind-scale-test-tfstate-lock
# =============================================================================

terraform {
  backend "s3" {
    bucket         = "overmind-scale-test-tfstate"
    key            = "scale-test/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "overmind-scale-test-tfstate-lock"
  }
}
