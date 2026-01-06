# =============================================================================
# Compute Scenarios
# Test scenarios that modify EC2/Lambda resources to trigger risks
# =============================================================================

# -----------------------------------------------------------------------------
# Scenario: ec2_start_all
# Starts all stopped EC2 instances
# Expected Risk: Cost increase (instances now running)
# Expected Blast Radius: All EC2 instances + their dependencies
# -----------------------------------------------------------------------------

# Use aws_ec2_instance_state to control instance state
# This is cleaner than local-exec and tracks state properly

resource "aws_ec2_instance_state" "start_us_east_1" {
  count = var.scenario == "ec2_start_all" ? length(module.aws_us_east_1.ec2_instance_ids) : 0

  provider    = aws.us_east_1
  instance_id = module.aws_us_east_1.ec2_instance_ids[count.index]
  state       = "running"
}

resource "aws_ec2_instance_state" "start_us_west_2" {
  count = var.scenario == "ec2_start_all" ? length(module.aws_us_west_2.ec2_instance_ids) : 0

  provider    = aws.us_west_2
  instance_id = module.aws_us_west_2.ec2_instance_ids[count.index]
  state       = "running"
}

resource "aws_ec2_instance_state" "start_eu_west_1" {
  count = var.scenario == "ec2_start_all" ? length(module.aws_eu_west_1.ec2_instance_ids) : 0

  provider    = aws.eu_west_1
  instance_id = module.aws_eu_west_1.ec2_instance_ids[count.index]
  state       = "running"
}

resource "aws_ec2_instance_state" "start_ap_southeast_1" {
  count = var.scenario == "ec2_start_all" ? length(module.aws_ap_southeast_1.ec2_instance_ids) : 0

  provider    = aws.ap_southeast_1
  instance_id = module.aws_ap_southeast_1.ec2_instance_ids[count.index]
  state       = "running"
}

# -----------------------------------------------------------------------------
# Note on ec2_downgrade and ec2_upgrade scenarios
# -----------------------------------------------------------------------------
# These scenarios require modifying the instance_type, which is set at the
# module level. To implement these, we have two options:
#
# 1. Pass a scenario-aware instance type to the modules (requires main.tf changes)
# 2. Use aws_instance data source + modification (complex, may cause replacement)
#
# For now, these are implemented via the module variable approach.
# See main.tf for the scenario_instance_type local variable.
# -----------------------------------------------------------------------------

