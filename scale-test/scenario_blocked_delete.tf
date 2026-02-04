# =============================================================================
# Scenario: blocked_sg_delete
# 
# This scenario attempts to delete a security group that has ENIs attached.
# AWS will block this with a DependencyViolation error.
#
# Purpose: Test how Overmind handles changes that would fail on apply due to
# cloud provider guardrails.
#
# Expected behavior:
# - Terraform plan succeeds (shows SG will be deleted)
# - Overmind analyzes the blast radius (ENIs using the SG)
# - Terraform apply FAILS with DependencyViolation
# =============================================================================

locals {
  scenario_blocked_sg_delete = var.scenario == "blocked_sg_delete"
  # Only create resources when NOT in the delete scenario
  create_deletable_resources = local.enable_aws && !local.scenario_blocked_sg_delete
}

# -----------------------------------------------------------------------------
# Dedicated Security Group for this scenario (us-east-1)
# 
# Created in baseline (scenario=none), deleted in blocked_sg_delete scenario.
# Has an ENI attached, so AWS will block the deletion.
# -----------------------------------------------------------------------------

resource "aws_security_group" "deletable_us_east_1" {
  count = local.create_deletable_resources ? 1 : 0

  provider    = aws.us_east_1
  name        = "scale-test-deletable-use1"
  description = "Security group that will be deleted in blocked_sg_delete scenario"
  vpc_id      = module.aws_us_east_1[0].vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  tags = merge(local.common_tags, {
    Name     = "scale-test-deletable-use1"
    Purpose  = "Scenario: blocked_sg_delete"
    Scenario = "deletable"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ENI attached to the deletable SG - creates the dependency that blocks deletion
resource "aws_network_interface" "deletable_us_east_1" {
  count = local.create_deletable_resources ? 1 : 0

  provider = aws.us_east_1

  subnet_id       = module.aws_us_east_1[0].private_subnet_ids[0]
  security_groups = [aws_security_group.deletable_us_east_1[0].id]

  tags = merge(local.common_tags, {
    Name     = "scale-test-deletable-eni-use1"
    Purpose  = "Creates dependency for blocked_sg_delete scenario"
    Scenario = "deletable"
  })
}

# -----------------------------------------------------------------------------
# Repeat for us-west-2
# -----------------------------------------------------------------------------

resource "aws_security_group" "deletable_us_west_2" {
  count = local.create_deletable_resources ? 1 : 0

  provider    = aws.us_west_2
  name        = "scale-test-deletable-usw2"
  description = "Security group that will be deleted in blocked_sg_delete scenario"
  vpc_id      = module.aws_us_west_2[0].vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  tags = merge(local.common_tags, {
    Name     = "scale-test-deletable-usw2"
    Purpose  = "Scenario: blocked_sg_delete"
    Scenario = "deletable"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_network_interface" "deletable_us_west_2" {
  count = local.create_deletable_resources ? 1 : 0

  provider = aws.us_west_2

  subnet_id       = module.aws_us_west_2[0].private_subnet_ids[0]
  security_groups = [aws_security_group.deletable_us_west_2[0].id]

  tags = merge(local.common_tags, {
    Name     = "scale-test-deletable-eni-usw2"
    Purpose  = "Creates dependency for blocked_sg_delete scenario"
    Scenario = "deletable"
  })
}

# -----------------------------------------------------------------------------
# Repeat for eu-west-1
# -----------------------------------------------------------------------------

resource "aws_security_group" "deletable_eu_west_1" {
  count = local.create_deletable_resources ? 1 : 0

  provider    = aws.eu_west_1
  name        = "scale-test-deletable-euw1"
  description = "Security group that will be deleted in blocked_sg_delete scenario"
  vpc_id      = module.aws_eu_west_1[0].vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  tags = merge(local.common_tags, {
    Name     = "scale-test-deletable-euw1"
    Purpose  = "Scenario: blocked_sg_delete"
    Scenario = "deletable"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_network_interface" "deletable_eu_west_1" {
  count = local.create_deletable_resources ? 1 : 0

  provider = aws.eu_west_1

  subnet_id       = module.aws_eu_west_1[0].private_subnet_ids[0]
  security_groups = [aws_security_group.deletable_eu_west_1[0].id]

  tags = merge(local.common_tags, {
    Name     = "scale-test-deletable-eni-euw1"
    Purpose  = "Creates dependency for blocked_sg_delete scenario"
    Scenario = "deletable"
  })
}

# -----------------------------------------------------------------------------
# Repeat for ap-southeast-1
# -----------------------------------------------------------------------------

resource "aws_security_group" "deletable_ap_southeast_1" {
  count = local.create_deletable_resources ? 1 : 0

  provider    = aws.ap_southeast_1
  name        = "scale-test-deletable-apse1"
  description = "Security group that will be deleted in blocked_sg_delete scenario"
  vpc_id      = module.aws_ap_southeast_1[0].vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  tags = merge(local.common_tags, {
    Name     = "scale-test-deletable-apse1"
    Purpose  = "Scenario: blocked_sg_delete"
    Scenario = "deletable"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_network_interface" "deletable_ap_southeast_1" {
  count = local.create_deletable_resources ? 1 : 0

  provider = aws.ap_southeast_1

  subnet_id       = module.aws_ap_southeast_1[0].private_subnet_ids[0]
  security_groups = [aws_security_group.deletable_ap_southeast_1[0].id]

  tags = merge(local.common_tags, {
    Name     = "scale-test-deletable-eni-apse1"
    Purpose  = "Creates dependency for blocked_sg_delete scenario"
    Scenario = "deletable"
  })
}

# -----------------------------------------------------------------------------
# Outputs for debugging
# -----------------------------------------------------------------------------

output "deletable_sg_ids" {
  description = "IDs of the deletable security groups (empty in blocked_sg_delete scenario)"
  value = {
    us_east_1      = try(aws_security_group.deletable_us_east_1[0].id, null)
    us_west_2      = try(aws_security_group.deletable_us_west_2[0].id, null)
    eu_west_1      = try(aws_security_group.deletable_eu_west_1[0].id, null)
    ap_southeast_1 = try(aws_security_group.deletable_ap_southeast_1[0].id, null)
  }
}

output "deletable_eni_ids" {
  description = "IDs of ENIs attached to deletable SGs"
  value = {
    us_east_1      = try(aws_network_interface.deletable_us_east_1[0].id, null)
    us_west_2      = try(aws_network_interface.deletable_us_west_2[0].id, null)
    eu_west_1      = try(aws_network_interface.deletable_eu_west_1[0].id, null)
    ap_southeast_1 = try(aws_network_interface.deletable_ap_southeast_1[0].id, null)
  }
}
