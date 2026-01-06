# =============================================================================
# High Fan-Out Scenarios
# Test scenarios that modify SHARED resources affecting many downstream items
# These create large blast radii for performance testing
# =============================================================================

# -----------------------------------------------------------------------------
# Scenario: shared_sg_open
# Opens SSH on the SHARED security group that ALL EC2 instances use
# Expected Blast Radius: All EC2 instances + their ENIs, EBS volumes, etc.
# At 100x: ~200 EC2 × 5 related resources = 1000+ items
# -----------------------------------------------------------------------------

resource "aws_security_group_rule" "shared_sg_open_us_east_1" {
  count = var.scenario == "shared_sg_open" ? 1 : 0

  provider          = aws.us_east_1
  security_group_id = module.aws_us_east_1.high_fanout_sg_id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HIGH FAN-OUT SCENARIO: SSH open to internet on SHARED SG"
}

resource "aws_security_group_rule" "shared_sg_open_us_west_2" {
  count = var.scenario == "shared_sg_open" ? 1 : 0

  provider          = aws.us_west_2
  security_group_id = module.aws_us_west_2.high_fanout_sg_id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HIGH FAN-OUT SCENARIO: SSH open to internet on SHARED SG"
}

resource "aws_security_group_rule" "shared_sg_open_eu_west_1" {
  count = var.scenario == "shared_sg_open" ? 1 : 0

  provider          = aws.eu_west_1
  security_group_id = module.aws_eu_west_1.high_fanout_sg_id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HIGH FAN-OUT SCENARIO: SSH open to internet on SHARED SG"
}

resource "aws_security_group_rule" "shared_sg_open_ap_southeast_1" {
  count = var.scenario == "shared_sg_open" ? 1 : 0

  provider          = aws.ap_southeast_1
  security_group_id = module.aws_ap_southeast_1.high_fanout_sg_id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HIGH FAN-OUT SCENARIO: SSH open to internet on SHARED SG"
}

# -----------------------------------------------------------------------------
# Scenario: shared_iam_admin
# Adds overly permissive admin policy to the SHARED Lambda role
# Expected Blast Radius: All Lambda functions + their CloudWatch logs, etc.
# At 100x: ~200 Lambda × 3 related resources = 600+ items
# -----------------------------------------------------------------------------

# Create admin policy in us-east-1 (IAM is global but we need a provider)
resource "aws_iam_policy" "shared_admin" {
  count = var.scenario == "shared_iam_admin" ? 1 : 0

  provider    = aws.us_east_1
  name        = "ovm-scale-shared-admin-policy-${local.unique_suffix}"
  description = "HIGH FAN-OUT SCENARIO: Overly permissive admin policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AdminAccess"
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Scenario = "shared_iam_admin"
    Warning  = "OVERLY_PERMISSIVE"
  })
}

# Attach admin policy to all shared Lambda roles
resource "aws_iam_role_policy_attachment" "shared_admin_us_east_1" {
  count = var.scenario == "shared_iam_admin" ? 1 : 0

  provider   = aws.us_east_1
  role       = module.aws_us_east_1.high_fanout_lambda_role_name
  policy_arn = aws_iam_policy.shared_admin[0].arn
}

resource "aws_iam_role_policy_attachment" "shared_admin_us_west_2" {
  count = var.scenario == "shared_iam_admin" ? 1 : 0

  provider   = aws.us_west_2
  role       = module.aws_us_west_2.high_fanout_lambda_role_name
  policy_arn = aws_iam_policy.shared_admin[0].arn
}

resource "aws_iam_role_policy_attachment" "shared_admin_eu_west_1" {
  count = var.scenario == "shared_iam_admin" ? 1 : 0

  provider   = aws.eu_west_1
  role       = module.aws_eu_west_1.high_fanout_lambda_role_name
  policy_arn = aws_iam_policy.shared_admin[0].arn
}

resource "aws_iam_role_policy_attachment" "shared_admin_ap_southeast_1" {
  count = var.scenario == "shared_iam_admin" ? 1 : 0

  provider   = aws.ap_southeast_1
  role       = module.aws_ap_southeast_1.high_fanout_lambda_role_name
  policy_arn = aws_iam_policy.shared_admin[0].arn
}

