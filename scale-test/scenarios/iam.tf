# =============================================================================
# IAM Scenarios
# Test scenarios that modify IAM policies to trigger permission escalation risks
# =============================================================================

# -----------------------------------------------------------------------------
# Scenario: iam_broadening
# Adds overly permissive "*:*" policy to Lambda execution roles
# Expected Risk: Permission escalation - roles can now do anything
# -----------------------------------------------------------------------------

# Create an overly permissive policy
resource "aws_iam_policy" "scenario_admin_us_east_1" {
  count = var.scenario == "iam_broadening" ? 1 : 0

  provider    = aws.us_east_1
  name        = "ovm-scale-scenario-admin-${local.unique_suffix}"
  description = "SCENARIO: Overly permissive policy - RISKY"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "FullAccess"
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Scenario = "iam_broadening"
    Warning  = "OVERLY_PERMISSIVE"
  })
}

# Attach the overly permissive policy to Lambda roles in each region
resource "aws_iam_role_policy_attachment" "scenario_admin_us_east_1" {
  count = var.scenario == "iam_broadening" ? length(module.aws_us_east_1.lambda_role_arns) : 0

  provider   = aws.us_east_1
  role       = element(split("/", module.aws_us_east_1.lambda_role_arns[count.index]), length(split("/", module.aws_us_east_1.lambda_role_arns[count.index])) - 1)
  policy_arn = aws_iam_policy.scenario_admin_us_east_1[0].arn
}

resource "aws_iam_policy" "scenario_admin_us_west_2" {
  count = var.scenario == "iam_broadening" ? 1 : 0

  provider    = aws.us_west_2
  name        = "ovm-scale-scenario-admin-usw2-${local.unique_suffix}"
  description = "SCENARIO: Overly permissive policy - RISKY"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "FullAccess"
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Scenario = "iam_broadening"
    Warning  = "OVERLY_PERMISSIVE"
  })
}

resource "aws_iam_role_policy_attachment" "scenario_admin_us_west_2" {
  count = var.scenario == "iam_broadening" ? length(module.aws_us_west_2.lambda_role_arns) : 0

  provider   = aws.us_west_2
  role       = element(split("/", module.aws_us_west_2.lambda_role_arns[count.index]), length(split("/", module.aws_us_west_2.lambda_role_arns[count.index])) - 1)
  policy_arn = aws_iam_policy.scenario_admin_us_west_2[0].arn
}

resource "aws_iam_policy" "scenario_admin_eu_west_1" {
  count = var.scenario == "iam_broadening" ? 1 : 0

  provider    = aws.eu_west_1
  name        = "ovm-scale-scenario-admin-euw1-${local.unique_suffix}"
  description = "SCENARIO: Overly permissive policy - RISKY"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "FullAccess"
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Scenario = "iam_broadening"
    Warning  = "OVERLY_PERMISSIVE"
  })
}

resource "aws_iam_role_policy_attachment" "scenario_admin_eu_west_1" {
  count = var.scenario == "iam_broadening" ? length(module.aws_eu_west_1.lambda_role_arns) : 0

  provider   = aws.eu_west_1
  role       = element(split("/", module.aws_eu_west_1.lambda_role_arns[count.index]), length(split("/", module.aws_eu_west_1.lambda_role_arns[count.index])) - 1)
  policy_arn = aws_iam_policy.scenario_admin_eu_west_1[0].arn
}

resource "aws_iam_policy" "scenario_admin_ap_southeast_1" {
  count = var.scenario == "iam_broadening" ? 1 : 0

  provider    = aws.ap_southeast_1
  name        = "ovm-scale-scenario-admin-apse1-${local.unique_suffix}"
  description = "SCENARIO: Overly permissive policy - RISKY"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "FullAccess"
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Scenario = "iam_broadening"
    Warning  = "OVERLY_PERMISSIVE"
  })
}

resource "aws_iam_role_policy_attachment" "scenario_admin_ap_southeast_1" {
  count = var.scenario == "iam_broadening" ? length(module.aws_ap_southeast_1.lambda_role_arns) : 0

  provider   = aws.ap_southeast_1
  role       = element(split("/", module.aws_ap_southeast_1.lambda_role_arns[count.index]), length(split("/", module.aws_ap_southeast_1.lambda_role_arns[count.index])) - 1)
  policy_arn = aws_iam_policy.scenario_admin_ap_southeast_1[0].arn
}

