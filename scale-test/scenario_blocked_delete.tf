# =============================================================================
# Scenario: blocked_sg_delete
# 
# This scenario attempts to delete a security group that has `prevent_destroy`
# lifecycle rule. Terraform will fail on apply with:
# "Error: Instance cannot be destroyed"
#
# Purpose: Test how Overmind handles changes that would fail on apply due to
# Terraform lifecycle rules (simulating cloud provider guardrails).
#
# Expected behavior:
# - Terraform plan succeeds (shows SG will be deleted)
# - Overmind analyzes the blast radius
# - Terraform apply FAILS with "prevent_destroy" error
# =============================================================================

locals {
  scenario_blocked_sg_delete = var.scenario == "blocked_sg_delete"
}

# -----------------------------------------------------------------------------
# Protected Security Group (us-east-1)
# 
# This SG has prevent_destroy = true, so Terraform will refuse to delete it.
# In the scenario, we set count = 0 to trigger a deletion attempt.
# -----------------------------------------------------------------------------

resource "aws_security_group" "protected_us_east_1" {
  # Always create in baseline, try to delete in scenario (will fail)
  count = local.enable_aws && !local.scenario_blocked_sg_delete ? 1 : 0

  provider    = aws.us_east_1
  name        = "scale-test-protected-use1"
  description = "Protected SG - deletion will fail due to prevent_destroy"
  vpc_id      = module.aws_us_east_1[0].vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "Allow HTTPS from internal networks"
  }

  tags = merge(local.common_tags, {
    Name      = "scale-test-protected-use1"
    Purpose   = "Scenario: blocked_sg_delete"
    Protected = "true"
  })

  # This causes apply to fail when trying to delete
  lifecycle {
    prevent_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Protected Security Group (us-west-2)
# -----------------------------------------------------------------------------

resource "aws_security_group" "protected_us_west_2" {
  count = local.enable_aws && !local.scenario_blocked_sg_delete ? 1 : 0

  provider    = aws.us_west_2
  name        = "scale-test-protected-usw2"
  description = "Protected SG - deletion will fail due to prevent_destroy"
  vpc_id      = module.aws_us_west_2[0].vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "Allow HTTPS from internal networks"
  }

  tags = merge(local.common_tags, {
    Name      = "scale-test-protected-usw2"
    Purpose   = "Scenario: blocked_sg_delete"
    Protected = "true"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Protected Security Group (eu-west-1)
# -----------------------------------------------------------------------------

resource "aws_security_group" "protected_eu_west_1" {
  count = local.enable_aws && !local.scenario_blocked_sg_delete ? 1 : 0

  provider    = aws.eu_west_1
  name        = "scale-test-protected-euw1"
  description = "Protected SG - deletion will fail due to prevent_destroy"
  vpc_id      = module.aws_eu_west_1[0].vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "Allow HTTPS from internal networks"
  }

  tags = merge(local.common_tags, {
    Name      = "scale-test-protected-euw1"
    Purpose   = "Scenario: blocked_sg_delete"
    Protected = "true"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Protected Security Group (ap-southeast-1)
# -----------------------------------------------------------------------------

resource "aws_security_group" "protected_ap_southeast_1" {
  count = local.enable_aws && !local.scenario_blocked_sg_delete ? 1 : 0

  provider    = aws.ap_southeast_1
  name        = "scale-test-protected-apse1"
  description = "Protected SG - deletion will fail due to prevent_destroy"
  vpc_id      = module.aws_ap_southeast_1[0].vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "Allow HTTPS from internal networks"
  }

  tags = merge(local.common_tags, {
    Name      = "scale-test-protected-apse1"
    Purpose   = "Scenario: blocked_sg_delete"
    Protected = "true"
  })

  lifecycle {
    prevent_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "protected_sg_ids" {
  description = "IDs of the protected security groups"
  value = {
    us_east_1      = try(aws_security_group.protected_us_east_1[0].id, null)
    us_west_2      = try(aws_security_group.protected_us_west_2[0].id, null)
    eu_west_1      = try(aws_security_group.protected_eu_west_1[0].id, null)
    ap_southeast_1 = try(aws_security_group.protected_ap_southeast_1[0].id, null)
  }
}
