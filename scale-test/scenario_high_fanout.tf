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
  count = local.enable_aws && var.scenario == "shared_sg_open" ? 1 : 0

  provider          = aws.us_east_1
  security_group_id = module.aws_us_east_1[0].high_fanout_sg_id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HIGH FAN-OUT SCENARIO: SSH open to internet on SHARED SG"
}

resource "aws_security_group_rule" "shared_sg_open_us_west_2" {
  count = local.enable_aws && var.scenario == "shared_sg_open" ? 1 : 0

  provider          = aws.us_west_2
  security_group_id = module.aws_us_west_2[0].high_fanout_sg_id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HIGH FAN-OUT SCENARIO: SSH open to internet on SHARED SG"
}

resource "aws_security_group_rule" "shared_sg_open_eu_west_1" {
  count = local.enable_aws && var.scenario == "shared_sg_open" ? 1 : 0

  provider          = aws.eu_west_1
  security_group_id = module.aws_eu_west_1[0].high_fanout_sg_id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HIGH FAN-OUT SCENARIO: SSH open to internet on SHARED SG"
}

resource "aws_security_group_rule" "shared_sg_open_ap_southeast_1" {
  count = local.enable_aws && var.scenario == "shared_sg_open" ? 1 : 0

  provider          = aws.ap_southeast_1
  security_group_id = module.aws_ap_southeast_1[0].high_fanout_sg_id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HIGH FAN-OUT SCENARIO: SSH open to internet on SHARED SG"
}
