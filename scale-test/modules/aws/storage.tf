# =============================================================================
# AWS Storage Resources
# Scale Testing Infrastructure for Overmind
# =============================================================================
# Creates S3 buckets (empty) and SSM Parameters for blast radius testing.
# =============================================================================

# -----------------------------------------------------------------------------
# S3 Buckets (Empty, for discovery only)
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "scale_test" {
  count = local.regional_count.s3_buckets

  bucket = "${local.name_prefix}-bucket-${count.index + 1}-${var.unique_suffix}"

  tags = merge(var.common_tags, {
    Name  = "${local.name_prefix}-bucket-${count.index + 1}"
    Index = count.index + 1
  })
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "scale_test" {
  count = local.regional_count.s3_buckets

  bucket = aws_s3_bucket.scale_test[count.index].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning (creates additional state for testing)
resource "aws_s3_bucket_versioning" "scale_test" {
  count = local.regional_count.s3_buckets

  bucket = aws_s3_bucket.scale_test[count.index].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "scale_test" {
  count = local.regional_count.s3_buckets

  bucket = aws_s3_bucket.scale_test[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Lifecycle rule to minimize any accidental data costs
resource "aws_s3_bucket_lifecycle_configuration" "scale_test" {
  count = local.regional_count.s3_buckets

  bucket = aws_s3_bucket.scale_test[count.index].id

  rule {
    id     = "cleanup"
    status = "Enabled"

    # Apply to all objects
    filter {}

    # Delete any objects after 1 day
    expiration {
      days = 1
    }

    # Delete incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }

    # Move to cheaper storage immediately
    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  depends_on = [aws_s3_bucket_versioning.scale_test]
}

# Bucket policy allowing Lambda access (creates cross-service edges)
resource "aws_s3_bucket_policy" "scale_test" {
  count = local.regional_count.s3_buckets

  bucket = aws_s3_bucket.scale_test[count.index].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaAccess"
        Effect = "Allow"
        Principal = {
          AWS = [for role in aws_iam_role.lambda_execution : role.arn]
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.scale_test[count.index].arn,
          "${aws_s3_bucket.scale_test[count.index].arn}/*"
        ]
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.scale_test]
}

# -----------------------------------------------------------------------------
# SSM Parameters
# -----------------------------------------------------------------------------

resource "aws_ssm_parameter" "scale_test" {
  count = local.regional_count.ssm_parameters

  name        = "/ovm-scale/${var.region}/param-${count.index + 1}"
  description = "Scale test parameter ${count.index + 1}"
  type        = "String"
  value = jsonencode({
    region     = var.region
    index      = count.index + 1
    multiplier = var.scale_multiplier
    created_at = timestamp()
    # Reference other resources to create edges
    vpc_id    = aws_vpc.main.id
    sns_topic = aws_sns_topic.scale_test[count.index % length(aws_sns_topic.scale_test)].arn
    sqs_queue = aws_sqs_queue.scale_test[count.index % length(aws_sqs_queue.scale_test)].arn
  })

  tags = merge(var.common_tags, {
    Name  = "${local.name_prefix}-param-${count.index + 1}"
    Index = count.index + 1
  })

  lifecycle {
    ignore_changes = [value] # Don't update on every apply due to timestamp
  }
}

# Secure parameters (SecureString type for variety)
resource "aws_ssm_parameter" "secure" {
  count = ceil(local.regional_count.ssm_parameters / 5) # 1 secure param per 5 regular

  name        = "/ovm-scale/${var.region}/secure-${count.index + 1}"
  description = "Scale test secure parameter ${count.index + 1}"
  type        = "SecureString"
  value       = "scale-test-secret-${count.index + 1}-${var.unique_suffix}"

  tags = merge(var.common_tags, {
    Name  = "${local.name_prefix}-secure-param-${count.index + 1}"
    Index = count.index + 1
    Type  = "secure"
  })
}

