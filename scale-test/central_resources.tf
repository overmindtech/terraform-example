# =============================================================================
# Central Resources for Maximum Relationship Density
# These resources are referenced by resources in ALL regions
# =============================================================================
#
# Architecture:
#   - Central SNS topic (us-east-1) -> All SQS queues subscribe
#   - Central S3 bucket (us-east-1) -> All Lambda functions reference
#
# Modifying these central resources affects ALL regions at once.
# =============================================================================

# -----------------------------------------------------------------------------
# Central SNS Topic
# All SQS queues in all regions subscribe to this topic
# -----------------------------------------------------------------------------

resource "aws_sns_topic" "central" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_east_1

  name = "ovm-scale-central-topic-${local.unique_suffix}"

  tags = merge(local.common_tags, {
    Name    = "ovm-scale-central-topic-${local.unique_suffix}"
    Purpose = "central-fanout"
    Warning = "ALL SQS queues subscribe to this topic"
  })
}

# SNS topic policy allowing cross-region subscriptions
resource "aws_sns_topic_policy" "central" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_east_1

  arn = aws_sns_topic.central[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossRegionSQS"
        Effect = "Allow"
        Principal = {
          Service = "sqs.amazonaws.com"
        }
        Action   = "sns:Subscribe"
        Resource = aws_sns_topic.central[0].arn
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Cross-Region SQS Subscriptions to Central SNS
# Each region's SQS queues subscribe to the central topic
# -----------------------------------------------------------------------------

# us-east-1 SQS -> Central SNS
resource "aws_sns_topic_subscription" "central_to_us_east_1" {
  count    = local.enable_aws ? length(module.aws_us_east_1[0].sqs_queue_arns) : 0
  provider = aws.us_east_1

  topic_arn = aws_sns_topic.central[0].arn
  protocol  = "sqs"
  endpoint  = module.aws_us_east_1[0].sqs_queue_arns[count.index]

  depends_on = [aws_sns_topic_policy.central]
}

# us-west-2 SQS -> Central SNS
resource "aws_sns_topic_subscription" "central_to_us_west_2" {
  count    = local.enable_aws ? length(module.aws_us_west_2[0].sqs_queue_arns) : 0
  provider = aws.us_east_1  # Subscription created in SNS region

  topic_arn = aws_sns_topic.central[0].arn
  protocol  = "sqs"
  endpoint  = module.aws_us_west_2[0].sqs_queue_arns[count.index]

  depends_on = [aws_sns_topic_policy.central]
}

# eu-west-1 SQS -> Central SNS
resource "aws_sns_topic_subscription" "central_to_eu_west_1" {
  count    = local.enable_aws ? length(module.aws_eu_west_1[0].sqs_queue_arns) : 0
  provider = aws.us_east_1

  topic_arn = aws_sns_topic.central[0].arn
  protocol  = "sqs"
  endpoint  = module.aws_eu_west_1[0].sqs_queue_arns[count.index]

  depends_on = [aws_sns_topic_policy.central]
}

# ap-southeast-1 SQS -> Central SNS
resource "aws_sns_topic_subscription" "central_to_ap_southeast_1" {
  count    = local.enable_aws ? length(module.aws_ap_southeast_1[0].sqs_queue_arns) : 0
  provider = aws.us_east_1

  topic_arn = aws_sns_topic.central[0].arn
  protocol  = "sqs"
  endpoint  = module.aws_ap_southeast_1[0].sqs_queue_arns[count.index]

  depends_on = [aws_sns_topic_policy.central]
}

# -----------------------------------------------------------------------------
# Central S3 Bucket
# All Lambda functions reference this bucket in their environment
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "central" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_east_1

  bucket = "ovm-scale-central-${local.unique_suffix}"

  tags = merge(local.common_tags, {
    Name    = "ovm-scale-central-${local.unique_suffix}"
    Purpose = "central-config"
    Warning = "ALL Lambda functions reference this bucket"
  })
}

resource "aws_s3_bucket_versioning" "central" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_east_1

  bucket = aws_s3_bucket.central[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# Bucket policy allowing cross-region Lambda access
resource "aws_s3_bucket_policy" "central" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_east_1

  bucket = aws_s3_bucket.central[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaAccess"
        Effect = "Allow"
        Principal = {
          AWS = [
            module.aws_us_east_1[0].high_fanout_lambda_role_arn,
            module.aws_us_west_2[0].high_fanout_lambda_role_arn,
            module.aws_eu_west_1[0].high_fanout_lambda_role_arn,
            module.aws_ap_southeast_1[0].high_fanout_lambda_role_arn
          ]
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.central[0].arn,
          "${aws_s3_bucket.central[0].arn}/*"
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Scenario: central_sns_change
# Modifies central SNS topic policy - affects ALL SQS queues in ALL regions
# -----------------------------------------------------------------------------

resource "aws_sns_topic_policy" "scenario_central_sns" {
  count    = local.enable_aws && var.scenario == "central_sns_change" ? 1 : 0
  provider = aws.us_east_1

  arn = aws_sns_topic.central[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossRegionSQS"
        Effect = "Allow"
        Principal = {
          Service = "sqs.amazonaws.com"
        }
        Action   = "sns:Subscribe"
        Resource = aws_sns_topic.central[0].arn
      },
      {
        Sid    = "ScenarioRestrictPublish"
        Effect = "Deny"
        Principal = "*"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.central[0].arn
        Condition = {
          StringNotEquals = {
            "aws:PrincipalAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Scenario: central_s3_change
# Modifies central S3 bucket policy - affects ALL Lambda functions
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_policy" "scenario_central_s3" {
  count    = local.enable_aws && var.scenario == "central_s3_change" ? 1 : 0
  provider = aws.us_east_1

  bucket = aws_s3_bucket.central[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaAccess"
        Effect = "Allow"
        Principal = {
          AWS = [
            module.aws_us_east_1[0].high_fanout_lambda_role_arn,
            module.aws_us_west_2[0].high_fanout_lambda_role_arn,
            module.aws_eu_west_1[0].high_fanout_lambda_role_arn,
            module.aws_ap_southeast_1[0].high_fanout_lambda_role_arn
          ]
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.central[0].arn,
          "${aws_s3_bucket.central[0].arn}/*"
        ]
      },
      {
        Sid    = "ScenarioDenyDelete"
        Effect = "Deny"
        Principal = "*"
        Action   = "s3:DeleteObject"
        Resource = "${aws_s3_bucket.central[0].arn}/*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Data source for account ID
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {
  provider = aws.us_east_1
}
