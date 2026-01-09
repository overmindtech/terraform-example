# =============================================================================
# VPC Peering Modification Scenario
# Modifies ALL VPC peering connections to maximize blast radius
# =============================================================================
#
# This scenario enables DNS resolution on ALL 6 peering connections.
# Each peering affects resources in 2 VPCs, so modifying all 6 touches
# every VPC multiple times, creating maximum relationship density.
#
# Expected Blast Radius:
# - At 10x: All 4 VPCs affected = ~1,200+ items
# - At 25x: ~2,500+ items
# - At 50x: ~5,000+ items
# =============================================================================

# -----------------------------------------------------------------------------
# us-east-1 <-> us-west-2
# -----------------------------------------------------------------------------

resource "aws_vpc_peering_connection_options" "scenario_dns_us_east_to_us_west_req" {
  count    = local.enable_aws && var.scenario == "vpc_peering_change" ? 1 : 0
  provider = aws.us_east_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_us_west[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "scenario_dns_us_east_to_us_west_acc" {
  count    = local.enable_aws && var.scenario == "vpc_peering_change" ? 1 : 0
  provider = aws.us_west_2

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_us_west[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

# -----------------------------------------------------------------------------
# us-east-1 <-> eu-west-1
# -----------------------------------------------------------------------------

resource "aws_vpc_peering_connection_options" "scenario_dns_us_east_to_eu_west_req" {
  count    = local.enable_aws && var.scenario == "vpc_peering_change" ? 1 : 0
  provider = aws.us_east_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_eu_west[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "scenario_dns_us_east_to_eu_west_acc" {
  count    = local.enable_aws && var.scenario == "vpc_peering_change" ? 1 : 0
  provider = aws.eu_west_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_eu_west[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

# -----------------------------------------------------------------------------
# us-east-1 <-> ap-southeast-1
# -----------------------------------------------------------------------------

resource "aws_vpc_peering_connection_options" "scenario_dns_us_east_to_ap_southeast_req" {
  count    = local.enable_aws && var.scenario == "vpc_peering_change" ? 1 : 0
  provider = aws.us_east_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_ap_southeast[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "scenario_dns_us_east_to_ap_southeast_acc" {
  count    = local.enable_aws && var.scenario == "vpc_peering_change" ? 1 : 0
  provider = aws.ap_southeast_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_ap_southeast[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

# -----------------------------------------------------------------------------
# us-west-2 <-> eu-west-1
# -----------------------------------------------------------------------------

resource "aws_vpc_peering_connection_options" "scenario_dns_us_west_to_eu_west_req" {
  count    = local.enable_aws && var.scenario == "vpc_peering_change" ? 1 : 0
  provider = aws.us_west_2

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_eu_west[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "scenario_dns_us_west_to_eu_west_acc" {
  count    = local.enable_aws && var.scenario == "vpc_peering_change" ? 1 : 0
  provider = aws.eu_west_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_eu_west[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

# -----------------------------------------------------------------------------
# us-west-2 <-> ap-southeast-1
# -----------------------------------------------------------------------------

resource "aws_vpc_peering_connection_options" "scenario_dns_us_west_to_ap_southeast_req" {
  count    = local.enable_aws && var.scenario == "vpc_peering_change" ? 1 : 0
  provider = aws.us_west_2

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_ap_southeast[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "scenario_dns_us_west_to_ap_southeast_acc" {
  count    = local.enable_aws && var.scenario == "vpc_peering_change" ? 1 : 0
  provider = aws.ap_southeast_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_ap_southeast[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

# -----------------------------------------------------------------------------
# eu-west-1 <-> ap-southeast-1
# -----------------------------------------------------------------------------

resource "aws_vpc_peering_connection_options" "scenario_dns_eu_west_to_ap_southeast_req" {
  count    = local.enable_aws && var.scenario == "vpc_peering_change" ? 1 : 0
  provider = aws.eu_west_1

  vpc_peering_connection_id = aws_vpc_peering_connection.eu_west_to_ap_southeast[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "scenario_dns_eu_west_to_ap_southeast_acc" {
  count    = local.enable_aws && var.scenario == "vpc_peering_change" ? 1 : 0
  provider = aws.ap_southeast_1

  vpc_peering_connection_id = aws_vpc_peering_connection.eu_west_to_ap_southeast[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}
