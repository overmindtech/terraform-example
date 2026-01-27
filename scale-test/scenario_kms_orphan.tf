# =============================================================================
# KMS Key Orphan Detection Scenario
# Tests Overmind's ability to detect risks when KMS keys are removed from state
# =============================================================================
#
# This scenario tests a dangerous pattern where:
# 1. A KMS key is removed from Terraform state via `terraform state rm`
# 2. Terraform sees no state for the key and plans to create a "new" one
# 3. Existing resources remain encrypted with the orphaned original key
# 4. If the orphaned key is later deleted, encrypted data becomes unrecoverable
#
# IMPORTANT NUANCE: prevent_destroy does NOT help!
# The lifecycle { prevent_destroy = true } rule only blocks `terraform destroy`.
# It does NOT block `terraform state rm` which is a state manipulation operation.
# Users may have a false sense of security with prevent_destroy set.
#
# This is NOT a variable-driven scenario - it requires manual state manipulation.
# See SCENARIOS.md for step-by-step test instructions.
# =============================================================================

# -----------------------------------------------------------------------------
# Central KMS Key
# Used by S3 buckets and EBS volumes across all regions
# This key creates the high-value encryption dependency that we test against
# -----------------------------------------------------------------------------

resource "aws_kms_key" "central" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_east_1

  description             = "Central encryption key for scale test resources"
  deletion_window_in_days = 30 # Maximum protection window
  enable_key_rotation     = true
  multi_region            = true

  tags = merge(local.common_tags, {
    Name    = "ovm-scale-central-kms-${local.unique_suffix}"
    Purpose = "central-encryption"
    Warning = "S3 buckets and EBS volumes encrypted with this key"
  })

  # IMPORTANT: prevent_destroy does NOT prevent terraform state rm!
  # This lifecycle rule only blocks `terraform destroy`, not state manipulation.
  # Users may have a false sense of security - the orphan pattern still occurs.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "central" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_east_1

  name          = "alias/ovm-scale-central-${local.unique_suffix}"
  target_key_id = aws_kms_key.central[0].key_id
}

# KMS key policy allowing cross-region access
resource "aws_kms_key_policy" "central" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_east_1

  key_id = aws_kms_key.central[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowS3Encryption"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowEC2Encryption"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# KMS-Encrypted S3 Bucket (us-east-1)
# This bucket explicitly uses the central KMS key for encryption
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "kms_encrypted" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_east_1

  bucket = "ovm-scale-kms-encrypted-${local.unique_suffix}"

  tags = merge(local.common_tags, {
    Name       = "ovm-scale-kms-encrypted-${local.unique_suffix}"
    Purpose    = "kms-encryption-test"
    Encryption = "KMS"
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "kms_encrypted" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_east_1

  bucket = aws_s3_bucket.kms_encrypted[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.central[0].arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "kms_encrypted" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_east_1

  bucket = aws_s3_bucket.kms_encrypted[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# KMS-Encrypted EBS Volume (us-east-1)
# Standalone EBS volume encrypted with the central KMS key
# -----------------------------------------------------------------------------

resource "aws_ebs_volume" "kms_encrypted" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_east_1

  availability_zone = "us-east-1a"
  size              = 10
  type              = "gp3"
  encrypted         = true
  kms_key_id        = aws_kms_key.central[0].arn

  tags = merge(local.common_tags, {
    Name       = "ovm-scale-kms-ebs-${local.unique_suffix}"
    Purpose    = "kms-encryption-test"
    Encryption = "KMS"
  })
}

# -----------------------------------------------------------------------------
# Scenario: kms_orphan_simulation
# Creates a SECOND KMS key to simulate what Terraform does after state rm
# Use this to test Overmind's duplicate key detection without actual state rm
# -----------------------------------------------------------------------------

resource "aws_kms_key" "duplicate" {
  count    = local.enable_aws && var.scenario == "kms_orphan_simulation" ? 1 : 0
  provider = aws.us_east_1

  description             = "DUPLICATE - Simulating orphaned key scenario"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name        = "ovm-scale-central-kms-DUPLICATE-${local.unique_suffix}"
    Purpose     = "orphan-simulation"
    Warning     = "This simulates a duplicate key created after state rm"
    OriginalKey = local.enable_aws ? aws_kms_key.central[0].arn : ""
  })
}

resource "aws_kms_alias" "duplicate" {
  count    = local.enable_aws && var.scenario == "kms_orphan_simulation" ? 1 : 0
  provider = aws.us_east_1

  name          = "alias/ovm-scale-central-DUPLICATE-${local.unique_suffix}"
  target_key_id = aws_kms_key.duplicate[0].key_id
}

# -----------------------------------------------------------------------------
# Outputs for testing
# -----------------------------------------------------------------------------

output "central_kms_key_arn" {
  description = "ARN of the central KMS key (use this for state rm testing)"
  value       = local.enable_aws ? aws_kms_key.central[0].arn : null
}

output "central_kms_key_id" {
  description = "ID of the central KMS key"
  value       = local.enable_aws ? aws_kms_key.central[0].key_id : null
}

output "kms_encrypted_bucket" {
  description = "S3 bucket encrypted with the central KMS key"
  value       = local.enable_aws ? aws_s3_bucket.kms_encrypted[0].id : null
}

output "kms_encrypted_ebs_volume" {
  description = "EBS volume encrypted with the central KMS key"
  value       = local.enable_aws ? aws_ebs_volume.kms_encrypted[0].id : null
}
