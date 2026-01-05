# =============================================================================
# AWS IAM Resources
# Scale Testing Infrastructure for Overmind
# =============================================================================
# Creates IAM roles and policies with cross-references for blast radius testing.
# =============================================================================

# -----------------------------------------------------------------------------
# Lambda Execution Role
# -----------------------------------------------------------------------------

resource "aws_iam_role" "lambda_execution" {
  count = local.regional_count.iam_roles

  name = "${local.name_prefix}-lambda-role-${count.index + 1}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name  = "${local.name_prefix}-lambda-role-${count.index + 1}"
    Index = count.index + 1
  })
}

# -----------------------------------------------------------------------------
# Lambda Basic Execution Policy Attachment
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  count = local.regional_count.iam_roles

  role       = aws_iam_role.lambda_execution[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# -----------------------------------------------------------------------------
# Custom Policy for Cross-Service Access (creates relationship density)
# -----------------------------------------------------------------------------

resource "aws_iam_policy" "cross_service" {
  count = local.regional_count.iam_roles

  name        = "${local.name_prefix}-cross-service-${count.index + 1}"
  description = "Cross-service access policy for scale testing"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSAccess"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "arn:aws:sqs:${var.region}:${data.aws_caller_identity.current.account_id}:ovm-scale-*"
      },
      {
        Sid    = "SNSAccess"
        Effect = "Allow"
        Action = [
          "sns:Publish",
          "sns:Subscribe"
        ]
        Resource = "arn:aws:sns:${var.region}:${data.aws_caller_identity.current.account_id}:ovm-scale-*"
      },
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::ovm-scale-*",
          "arn:aws:s3:::ovm-scale-*/*"
        ]
      },
      {
        Sid    = "SSMAccess"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/ovm-scale/*"
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/ovm-scale-*:*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name  = "${local.name_prefix}-cross-service-${count.index + 1}"
    Index = count.index + 1
  })
}

# -----------------------------------------------------------------------------
# Attach Custom Policy to Lambda Roles
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "cross_service" {
  count = local.regional_count.iam_roles

  role       = aws_iam_role.lambda_execution[count.index].name
  policy_arn = aws_iam_policy.cross_service[count.index].arn
}

# -----------------------------------------------------------------------------
# EC2 Instance Profile (for stopped instances)
# -----------------------------------------------------------------------------

resource "aws_iam_role" "ec2_instance" {
  name = "${local.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-ec2-role"
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2_instance.name

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-ec2-profile"
  })
}

# -----------------------------------------------------------------------------
# SSM Managed Instance Policy for EC2
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

