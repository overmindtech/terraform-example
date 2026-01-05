# =============================================================================
# AWS Messaging Resources
# Scale Testing Infrastructure for Overmind
# =============================================================================
# Creates SQS queues and SNS topics with cross-references for blast radius.
# =============================================================================

# -----------------------------------------------------------------------------
# SQS Queues
# -----------------------------------------------------------------------------

resource "aws_sqs_queue" "scale_test" {
  count = local.regional_count.sqs_queues

  name                       = "${local.name_prefix}-queue-${count.index + 1}"
  delay_seconds              = 0
  max_message_size           = 262144 # 256 KB
  message_retention_seconds  = 345600 # 4 days (minimum for cost)
  receive_wait_time_seconds  = 0
  visibility_timeout_seconds = 30

  # Enable server-side encryption
  sqs_managed_sse_enabled = true

  tags = merge(var.common_tags, {
    Name  = "${local.name_prefix}-queue-${count.index + 1}"
    Index = count.index + 1
  })
}

# Dead letter queues for some SQS queues (creates additional relationships)
resource "aws_sqs_queue" "dlq" {
  count = ceil(local.regional_count.sqs_queues / 3) # 1 DLQ per 3 queues

  name                      = "${local.name_prefix}-dlq-${count.index + 1}"
  message_retention_seconds = 1209600 # 14 days
  sqs_managed_sse_enabled   = true

  tags = merge(var.common_tags, {
    Name  = "${local.name_prefix}-dlq-${count.index + 1}"
    Index = count.index + 1
    Type  = "dead-letter-queue"
  })
}

# -----------------------------------------------------------------------------
# SNS Topics
# -----------------------------------------------------------------------------

resource "aws_sns_topic" "scale_test" {
  count = local.regional_count.sns_topics

  name = "${local.name_prefix}-topic-${count.index + 1}"

  tags = merge(var.common_tags, {
    Name  = "${local.name_prefix}-topic-${count.index + 1}"
    Index = count.index + 1
  })
}

# -----------------------------------------------------------------------------
# SQS Queue Policies (Allow SNS to send messages - creates cross-service edges)
# -----------------------------------------------------------------------------

resource "aws_sqs_queue_policy" "sns_to_sqs" {
  count = local.regional_count.sqs_queues

  queue_url = aws_sqs_queue.scale_test[count.index].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSNSMessages"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.scale_test[count.index].arn
        Condition = {
          ArnEquals = {
            # Each queue references a specific SNS topic (circular relationship pattern)
            "aws:SourceArn" = aws_sns_topic.scale_test[count.index % length(aws_sns_topic.scale_test)].arn
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# SNS Subscriptions (SNS -> SQS relationships)
# -----------------------------------------------------------------------------

resource "aws_sns_topic_subscription" "sqs" {
  count = local.regional_count.sqs_queues

  topic_arn = aws_sns_topic.scale_test[count.index % length(aws_sns_topic.scale_test)].arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.scale_test[count.index].arn

  # Raw message delivery (no JSON wrapping)
  raw_message_delivery = true
}

# -----------------------------------------------------------------------------
# SNS Topic Policy (Allow Lambda to publish)
# -----------------------------------------------------------------------------

resource "aws_sns_topic_policy" "lambda_publish" {
  count = local.regional_count.sns_topics

  arn = aws_sns_topic.scale_test[count.index].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaPublish"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.scale_test[count.index].arn
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AllowAccountPublish"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.scale_test[count.index].arn
      }
    ]
  })
}

