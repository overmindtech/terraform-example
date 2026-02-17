# =============================================================================
# Combined Scenarios
# Scenarios that trigger MULTIPLE changes simultaneously for maximum blast radius
# =============================================================================

# -----------------------------------------------------------------------------
# Scenario: combined_network
# Combines vpc_peering_change + shared_sg_open for maximum network blast radius
# Expected Blast Radius: 1,200-1,500 items at 25x (vs 852 for vpc_peering alone)
# -----------------------------------------------------------------------------

locals {
  scenario_combined_network = local.enable_aws && var.scenario == "combined_network"
  scenario_combined_all     = local.enable_aws && var.scenario == "combined_all"
  scenario_combined_max     = local.enable_aws && var.scenario == "combined_max"
}

# --- VPC Peering DNS Changes (from vpc_peering_change) ---

resource "aws_vpc_peering_connection_options" "combined_dns_us_east_to_us_west_req" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.us_east_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_us_west[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "combined_dns_us_east_to_us_west_acc" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.us_west_2

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_us_west[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "combined_dns_us_east_to_eu_west_req" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.us_east_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_eu_west[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "combined_dns_us_east_to_eu_west_acc" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.eu_west_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_eu_west[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "combined_dns_us_east_to_ap_southeast_req" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.us_east_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_ap_southeast[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "combined_dns_us_east_to_ap_southeast_acc" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.ap_southeast_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_ap_southeast[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "combined_dns_us_west_to_eu_west_req" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.us_west_2

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_eu_west[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "combined_dns_us_west_to_eu_west_acc" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.eu_west_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_eu_west[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "combined_dns_us_west_to_ap_southeast_req" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.us_west_2

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_ap_southeast[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "combined_dns_us_west_to_ap_southeast_acc" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.ap_southeast_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_ap_southeast[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "combined_dns_eu_west_to_ap_southeast_req" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.eu_west_1

  vpc_peering_connection_id = aws_vpc_peering_connection.eu_west_to_ap_southeast[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "combined_dns_eu_west_to_ap_southeast_acc" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.ap_southeast_1

  vpc_peering_connection_id = aws_vpc_peering_connection.eu_west_to_ap_southeast[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

# NOTE: Shared SG SSH open is now handled inline in the module's
# aws_security_group.high_fanout via local.scenario_open_ssh.
# See scenario_high_fanout.tf for details.

# -----------------------------------------------------------------------------
# Scenario: combined_all
# Combines ALL high-fanout scenarios (except central_s3 which times out)
# - vpc_peering_change: Modify all 6 VPC peerings
# - shared_sg_open: Open SSH on all shared SGs
# - central_sns_change: Modify central SNS policy
# Expected Blast Radius: 1,500-2,000 items at 25x
# -----------------------------------------------------------------------------

# --- VPC Peering DNS Changes ---

resource "aws_vpc_peering_connection_options" "all_dns_us_east_to_us_west_req" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.us_east_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_us_west[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "all_dns_us_east_to_us_west_acc" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.us_west_2

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_us_west[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "all_dns_us_east_to_eu_west_req" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.us_east_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_eu_west[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "all_dns_us_east_to_eu_west_acc" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.eu_west_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_eu_west[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "all_dns_us_east_to_ap_southeast_req" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.us_east_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_ap_southeast[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "all_dns_us_east_to_ap_southeast_acc" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.ap_southeast_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_ap_southeast[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "all_dns_us_west_to_eu_west_req" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.us_west_2

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_eu_west[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "all_dns_us_west_to_eu_west_acc" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.eu_west_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_eu_west[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "all_dns_us_west_to_ap_southeast_req" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.us_west_2

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_ap_southeast[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "all_dns_us_west_to_ap_southeast_acc" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.ap_southeast_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_ap_southeast[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "all_dns_eu_west_to_ap_southeast_req" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.eu_west_1

  vpc_peering_connection_id = aws_vpc_peering_connection.eu_west_to_ap_southeast[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "all_dns_eu_west_to_ap_southeast_acc" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.ap_southeast_1

  vpc_peering_connection_id = aws_vpc_peering_connection.eu_west_to_ap_southeast[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

# NOTE: Shared SG SSH open is now handled inline in the module's
# aws_security_group.high_fanout via local.scenario_open_ssh.

# NOTE: Central SNS policy change is now handled inline in
# aws_sns_topic_policy.central via local.scenario_restrict_sns_publish.

# =============================================================================
# Scenario: combined_max
# MAXIMUM blast radius scenario - combines everything for stress testing
# - VPC peering DNS changes (6 peerings)
# - Shared SG open ALL PORTS (not just SSH)
# - Central SNS policy change
# - Lambda timeout changes (via main.tf locals)
# Expected Blast Radius: 1,200-1,500 items at 25x
# =============================================================================

# --- VPC Peering DNS Changes ---

resource "aws_vpc_peering_connection_options" "max_dns_us_east_to_us_west_req" {
  count    = local.scenario_combined_max ? 1 : 0
  provider = aws.us_east_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_us_west[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "max_dns_us_east_to_us_west_acc" {
  count    = local.scenario_combined_max ? 1 : 0
  provider = aws.us_west_2

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_us_west[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "max_dns_us_east_to_eu_west_req" {
  count    = local.scenario_combined_max ? 1 : 0
  provider = aws.us_east_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_eu_west[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "max_dns_us_east_to_eu_west_acc" {
  count    = local.scenario_combined_max ? 1 : 0
  provider = aws.eu_west_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_eu_west[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "max_dns_us_east_to_ap_southeast_req" {
  count    = local.scenario_combined_max ? 1 : 0
  provider = aws.us_east_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_ap_southeast[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "max_dns_us_east_to_ap_southeast_acc" {
  count    = local.scenario_combined_max ? 1 : 0
  provider = aws.ap_southeast_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_ap_southeast[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "max_dns_us_west_to_eu_west_req" {
  count    = local.scenario_combined_max ? 1 : 0
  provider = aws.us_west_2

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_eu_west[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "max_dns_us_west_to_eu_west_acc" {
  count    = local.scenario_combined_max ? 1 : 0
  provider = aws.eu_west_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_eu_west[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "max_dns_us_west_to_ap_southeast_req" {
  count    = local.scenario_combined_max ? 1 : 0
  provider = aws.us_west_2

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_ap_southeast[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "max_dns_us_west_to_ap_southeast_acc" {
  count    = local.scenario_combined_max ? 1 : 0
  provider = aws.ap_southeast_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_ap_southeast[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "max_dns_eu_west_to_ap_southeast_req" {
  count    = local.scenario_combined_max ? 1 : 0
  provider = aws.eu_west_1

  vpc_peering_connection_id = aws_vpc_peering_connection.eu_west_to_ap_southeast[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "max_dns_eu_west_to_ap_southeast_acc" {
  count    = local.scenario_combined_max ? 1 : 0
  provider = aws.ap_southeast_1

  vpc_peering_connection_id = aws_vpc_peering_connection.eu_west_to_ap_southeast[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

# NOTE: Shared SG ALL PORTS open is now handled inline in the module's
# aws_security_group.high_fanout via local.scenario_open_all_ports.

# NOTE: Central SNS policy change is now handled inline in
# aws_sns_topic_policy.central via local.scenario_restrict_sns_publish.
