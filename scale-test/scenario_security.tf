# =============================================================================
# Security Scenarios
# Test scenarios that modify security groups to trigger security risks
# =============================================================================

# -----------------------------------------------------------------------------
# Scenario: sg_open_ssh
# Opens SSH (port 22) to the internet on shared security groups
# Expected Risk: Security exposure - SSH accessible from anywhere
# -----------------------------------------------------------------------------

resource "aws_security_group_rule" "scenario_open_ssh_us_east_1" {
  count = var.scenario == "sg_open_ssh" ? 1 : 0

  provider          = aws.us_east_1
  security_group_id = module.aws_us_east_1.security_group_ids[0]
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "SCENARIO: SSH open to internet - RISKY"
}

resource "aws_security_group_rule" "scenario_open_ssh_us_west_2" {
  count = var.scenario == "sg_open_ssh" ? 1 : 0

  provider          = aws.us_west_2
  security_group_id = module.aws_us_west_2.security_group_ids[0]
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "SCENARIO: SSH open to internet - RISKY"
}

resource "aws_security_group_rule" "scenario_open_ssh_eu_west_1" {
  count = var.scenario == "sg_open_ssh" ? 1 : 0

  provider          = aws.eu_west_1
  security_group_id = module.aws_eu_west_1.security_group_ids[0]
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "SCENARIO: SSH open to internet - RISKY"
}

resource "aws_security_group_rule" "scenario_open_ssh_ap_southeast_1" {
  count = var.scenario == "sg_open_ssh" ? 1 : 0

  provider          = aws.ap_southeast_1
  security_group_id = module.aws_ap_southeast_1.security_group_ids[0]
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "SCENARIO: SSH open to internet - RISKY"
}

# -----------------------------------------------------------------------------
# Scenario: sg_open_all
# Opens ALL ports to the internet on shared security groups
# Expected Risk: Critical security exposure - all traffic allowed
# -----------------------------------------------------------------------------

resource "aws_security_group_rule" "scenario_open_all_us_east_1" {
  count = var.scenario == "sg_open_all" ? 1 : 0

  provider          = aws.us_east_1
  security_group_id = module.aws_us_east_1.security_group_ids[0]
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "SCENARIO: ALL PORTS open to internet - CRITICAL"
}

resource "aws_security_group_rule" "scenario_open_all_us_west_2" {
  count = var.scenario == "sg_open_all" ? 1 : 0

  provider          = aws.us_west_2
  security_group_id = module.aws_us_west_2.security_group_ids[0]
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "SCENARIO: ALL PORTS open to internet - CRITICAL"
}

resource "aws_security_group_rule" "scenario_open_all_eu_west_1" {
  count = var.scenario == "sg_open_all" ? 1 : 0

  provider          = aws.eu_west_1
  security_group_id = module.aws_eu_west_1.security_group_ids[0]
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "SCENARIO: ALL PORTS open to internet - CRITICAL"
}

resource "aws_security_group_rule" "scenario_open_all_ap_southeast_1" {
  count = var.scenario == "sg_open_all" ? 1 : 0

  provider          = aws.ap_southeast_1
  security_group_id = module.aws_ap_southeast_1.security_group_ids[0]
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "SCENARIO: ALL PORTS open to internet - CRITICAL"
}

