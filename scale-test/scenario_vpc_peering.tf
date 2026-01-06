# =============================================================================
# VPC Peering Modification Scenario
# Modifies VPC peering connection options to trigger blast radius analysis
# =============================================================================
#
# This scenario modifies the DNS resolution settings on VPC peering connections.
# Because VPCs are connected in a mesh, modifying any peering connection
# affects ALL resources in BOTH connected VPCs.
#
# Expected Blast Radius:
# - At 10x: Modifying 1 peering → affects 2 VPCs → ~870 resources
# - At 100x: Same multiplier effect across larger resource base
# =============================================================================

# -----------------------------------------------------------------------------
# Scenario: vpc_peering_change
# Enables DNS resolution on the us-east-1 ↔ us-west-2 peering connection
# This affects ALL resources in both VPCs
# -----------------------------------------------------------------------------

resource "aws_vpc_peering_connection_options" "scenario_dns_us_east_1" {
  count = var.scenario == "vpc_peering_change" ? 1 : 0

  provider = aws.us_east_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_us_west.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "scenario_dns_us_west_2" {
  count = var.scenario == "vpc_peering_change" ? 1 : 0

  provider = aws.us_west_2

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_us_west.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

