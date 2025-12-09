# iam.tf
# IAM Role and Instance Profile

resource "aws_iam_role" "api_server" {
  count = var.enabled ? 1 : 0

  name = "${local.name_prefix}-api-role"

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

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-api-role"
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  count = var.enabled ? 1 : 0

  role       = aws_iam_role.api_server[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count = var.enabled ? 1 : 0

  role       = aws_iam_role.api_server[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "api_server" {
  count = var.enabled ? 1 : 0

  name = "${local.name_prefix}-api-profile"
  role = aws_iam_role.api_server[0].name

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-api-profile"
  })
}

