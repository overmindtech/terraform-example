# =============================================================================
# Cross-Region VPC Peering
# Creates a mesh of VPC peering connections for high relationship density
# =============================================================================
#
# Topology:
#   us-east-1 ←→ us-west-2 ←→ eu-west-1 ←→ ap-southeast-1
#       ↑___________↓            ↑______________↓
#       ↑________________________↓
#
# This creates 6 peering connections forming a full mesh.
# Modifying any peering affects ALL resources in BOTH connected VPCs.
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Peering: us-east-1 ↔ us-west-2
# -----------------------------------------------------------------------------

resource "aws_vpc_peering_connection" "us_east_to_us_west" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_east_1

  vpc_id      = module.aws_us_east_1[0].vpc_id
  peer_vpc_id = module.aws_us_west_2[0].vpc_id
  peer_region = "us-west-2"
  auto_accept = false

  tags = merge(local.common_tags, {
    Name = "ovm-scale-peer-useast1-uswest2-${local.unique_suffix}"
    Side = "requester"
  })
}

resource "aws_vpc_peering_connection_accepter" "us_west_from_us_east" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_west_2

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_us_west[0].id
  auto_accept               = true

  tags = merge(local.common_tags, {
    Name = "ovm-scale-peer-useast1-uswest2-${local.unique_suffix}"
    Side = "accepter"
  })
}

# Routes for us-east-1 → us-west-2
resource "aws_route" "us_east_to_us_west_public" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_east_1

  route_table_id            = module.aws_us_east_1[0].public_route_table_id
  destination_cidr_block    = module.aws_us_west_2[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_us_west[0].id

  depends_on = [aws_vpc_peering_connection_accepter.us_west_from_us_east]
}

resource "aws_route" "us_east_to_us_west_private" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_east_1

  route_table_id            = module.aws_us_east_1[0].private_route_table_id
  destination_cidr_block    = module.aws_us_west_2[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_us_west[0].id

  depends_on = [aws_vpc_peering_connection_accepter.us_west_from_us_east]
}

# Routes for us-west-2 → us-east-1
resource "aws_route" "us_west_to_us_east_public" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_west_2

  route_table_id            = module.aws_us_west_2[0].public_route_table_id
  destination_cidr_block    = module.aws_us_east_1[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_us_west[0].id

  depends_on = [aws_vpc_peering_connection_accepter.us_west_from_us_east]
}

resource "aws_route" "us_west_to_us_east_private" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_west_2

  route_table_id            = module.aws_us_west_2[0].private_route_table_id
  destination_cidr_block    = module.aws_us_east_1[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_us_west[0].id

  depends_on = [aws_vpc_peering_connection_accepter.us_west_from_us_east]
}

# -----------------------------------------------------------------------------
# VPC Peering: us-east-1 ↔ eu-west-1
# -----------------------------------------------------------------------------

resource "aws_vpc_peering_connection" "us_east_to_eu_west" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_east_1

  vpc_id      = module.aws_us_east_1[0].vpc_id
  peer_vpc_id = module.aws_eu_west_1[0].vpc_id
  peer_region = "eu-west-1"
  auto_accept = false

  tags = merge(local.common_tags, {
    Name = "ovm-scale-peer-useast1-euwest1-${local.unique_suffix}"
    Side = "requester"
  })
}

resource "aws_vpc_peering_connection_accepter" "eu_west_from_us_east" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.eu_west_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_eu_west[0].id
  auto_accept               = true

  tags = merge(local.common_tags, {
    Name = "ovm-scale-peer-useast1-euwest1-${local.unique_suffix}"
    Side = "accepter"
  })
}

# Routes for us-east-1 → eu-west-1
resource "aws_route" "us_east_to_eu_west_public" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_east_1

  route_table_id            = module.aws_us_east_1[0].public_route_table_id
  destination_cidr_block    = module.aws_eu_west_1[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_eu_west[0].id

  depends_on = [aws_vpc_peering_connection_accepter.eu_west_from_us_east]
}

resource "aws_route" "us_east_to_eu_west_private" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_east_1

  route_table_id            = module.aws_us_east_1[0].private_route_table_id
  destination_cidr_block    = module.aws_eu_west_1[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_eu_west[0].id

  depends_on = [aws_vpc_peering_connection_accepter.eu_west_from_us_east]
}

# Routes for eu-west-1 → us-east-1
resource "aws_route" "eu_west_to_us_east_public" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.eu_west_1

  route_table_id            = module.aws_eu_west_1[0].public_route_table_id
  destination_cidr_block    = module.aws_us_east_1[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_eu_west[0].id

  depends_on = [aws_vpc_peering_connection_accepter.eu_west_from_us_east]
}

resource "aws_route" "eu_west_to_us_east_private" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.eu_west_1

  route_table_id            = module.aws_eu_west_1[0].private_route_table_id
  destination_cidr_block    = module.aws_us_east_1[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_eu_west[0].id

  depends_on = [aws_vpc_peering_connection_accepter.eu_west_from_us_east]
}

# -----------------------------------------------------------------------------
# VPC Peering: us-east-1 ↔ ap-southeast-1
# -----------------------------------------------------------------------------

resource "aws_vpc_peering_connection" "us_east_to_ap_southeast" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_east_1

  vpc_id      = module.aws_us_east_1[0].vpc_id
  peer_vpc_id = module.aws_ap_southeast_1[0].vpc_id
  peer_region = "ap-southeast-1"
  auto_accept = false

  tags = merge(local.common_tags, {
    Name = "ovm-scale-peer-useast1-apsoutheast1-${local.unique_suffix}"
    Side = "requester"
  })
}

resource "aws_vpc_peering_connection_accepter" "ap_southeast_from_us_east" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.ap_southeast_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_ap_southeast[0].id
  auto_accept               = true

  tags = merge(local.common_tags, {
    Name = "ovm-scale-peer-useast1-apsoutheast1-${local.unique_suffix}"
    Side = "accepter"
  })
}

# Routes for us-east-1 → ap-southeast-1
resource "aws_route" "us_east_to_ap_southeast_public" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_east_1

  route_table_id            = module.aws_us_east_1[0].public_route_table_id
  destination_cidr_block    = module.aws_ap_southeast_1[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_ap_southeast[0].id

  depends_on = [aws_vpc_peering_connection_accepter.ap_southeast_from_us_east]
}

resource "aws_route" "us_east_to_ap_southeast_private" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_east_1

  route_table_id            = module.aws_us_east_1[0].private_route_table_id
  destination_cidr_block    = module.aws_ap_southeast_1[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_ap_southeast[0].id

  depends_on = [aws_vpc_peering_connection_accepter.ap_southeast_from_us_east]
}

# Routes for ap-southeast-1 → us-east-1
resource "aws_route" "ap_southeast_to_us_east_public" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.ap_southeast_1

  route_table_id            = module.aws_ap_southeast_1[0].public_route_table_id
  destination_cidr_block    = module.aws_us_east_1[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_ap_southeast[0].id

  depends_on = [aws_vpc_peering_connection_accepter.ap_southeast_from_us_east]
}

resource "aws_route" "ap_southeast_to_us_east_private" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.ap_southeast_1

  route_table_id            = module.aws_ap_southeast_1[0].private_route_table_id
  destination_cidr_block    = module.aws_us_east_1[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_ap_southeast[0].id

  depends_on = [aws_vpc_peering_connection_accepter.ap_southeast_from_us_east]
}

# -----------------------------------------------------------------------------
# VPC Peering: us-west-2 ↔ eu-west-1
# -----------------------------------------------------------------------------

resource "aws_vpc_peering_connection" "us_west_to_eu_west" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_west_2

  vpc_id      = module.aws_us_west_2[0].vpc_id
  peer_vpc_id = module.aws_eu_west_1[0].vpc_id
  peer_region = "eu-west-1"
  auto_accept = false

  tags = merge(local.common_tags, {
    Name = "ovm-scale-peer-uswest2-euwest1-${local.unique_suffix}"
    Side = "requester"
  })
}

resource "aws_vpc_peering_connection_accepter" "eu_west_from_us_west" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.eu_west_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_eu_west[0].id
  auto_accept               = true

  tags = merge(local.common_tags, {
    Name = "ovm-scale-peer-uswest2-euwest1-${local.unique_suffix}"
    Side = "accepter"
  })
}

# Routes for us-west-2 → eu-west-1
resource "aws_route" "us_west_to_eu_west_public" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_west_2

  route_table_id            = module.aws_us_west_2[0].public_route_table_id
  destination_cidr_block    = module.aws_eu_west_1[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_eu_west[0].id

  depends_on = [aws_vpc_peering_connection_accepter.eu_west_from_us_west]
}

resource "aws_route" "us_west_to_eu_west_private" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_west_2

  route_table_id            = module.aws_us_west_2[0].private_route_table_id
  destination_cidr_block    = module.aws_eu_west_1[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_eu_west[0].id

  depends_on = [aws_vpc_peering_connection_accepter.eu_west_from_us_west]
}

# Routes for eu-west-1 → us-west-2
resource "aws_route" "eu_west_to_us_west_public" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.eu_west_1

  route_table_id            = module.aws_eu_west_1[0].public_route_table_id
  destination_cidr_block    = module.aws_us_west_2[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_eu_west[0].id

  depends_on = [aws_vpc_peering_connection_accepter.eu_west_from_us_west]
}

resource "aws_route" "eu_west_to_us_west_private" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.eu_west_1

  route_table_id            = module.aws_eu_west_1[0].private_route_table_id
  destination_cidr_block    = module.aws_us_west_2[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_eu_west[0].id

  depends_on = [aws_vpc_peering_connection_accepter.eu_west_from_us_west]
}

# -----------------------------------------------------------------------------
# VPC Peering: us-west-2 ↔ ap-southeast-1
# -----------------------------------------------------------------------------

resource "aws_vpc_peering_connection" "us_west_to_ap_southeast" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_west_2

  vpc_id      = module.aws_us_west_2[0].vpc_id
  peer_vpc_id = module.aws_ap_southeast_1[0].vpc_id
  peer_region = "ap-southeast-1"
  auto_accept = false

  tags = merge(local.common_tags, {
    Name = "ovm-scale-peer-uswest2-apsoutheast1-${local.unique_suffix}"
    Side = "requester"
  })
}

resource "aws_vpc_peering_connection_accepter" "ap_southeast_from_us_west" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.ap_southeast_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_ap_southeast[0].id
  auto_accept               = true

  tags = merge(local.common_tags, {
    Name = "ovm-scale-peer-uswest2-apsoutheast1-${local.unique_suffix}"
    Side = "accepter"
  })
}

# Routes for us-west-2 → ap-southeast-1
resource "aws_route" "us_west_to_ap_southeast_public" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_west_2

  route_table_id            = module.aws_us_west_2[0].public_route_table_id
  destination_cidr_block    = module.aws_ap_southeast_1[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_ap_southeast[0].id

  depends_on = [aws_vpc_peering_connection_accepter.ap_southeast_from_us_west]
}

resource "aws_route" "us_west_to_ap_southeast_private" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.us_west_2

  route_table_id            = module.aws_us_west_2[0].private_route_table_id
  destination_cidr_block    = module.aws_ap_southeast_1[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_ap_southeast[0].id

  depends_on = [aws_vpc_peering_connection_accepter.ap_southeast_from_us_west]
}

# Routes for ap-southeast-1 → us-west-2
resource "aws_route" "ap_southeast_to_us_west_public" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.ap_southeast_1

  route_table_id            = module.aws_ap_southeast_1[0].public_route_table_id
  destination_cidr_block    = module.aws_us_west_2[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_ap_southeast[0].id

  depends_on = [aws_vpc_peering_connection_accepter.ap_southeast_from_us_west]
}

resource "aws_route" "ap_southeast_to_us_west_private" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.ap_southeast_1

  route_table_id            = module.aws_ap_southeast_1[0].private_route_table_id
  destination_cidr_block    = module.aws_us_west_2[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_ap_southeast[0].id

  depends_on = [aws_vpc_peering_connection_accepter.ap_southeast_from_us_west]
}

# -----------------------------------------------------------------------------
# VPC Peering: eu-west-1 ↔ ap-southeast-1
# -----------------------------------------------------------------------------

resource "aws_vpc_peering_connection" "eu_west_to_ap_southeast" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.eu_west_1

  vpc_id      = module.aws_eu_west_1[0].vpc_id
  peer_vpc_id = module.aws_ap_southeast_1[0].vpc_id
  peer_region = "ap-southeast-1"
  auto_accept = false

  tags = merge(local.common_tags, {
    Name = "ovm-scale-peer-euwest1-apsoutheast1-${local.unique_suffix}"
    Side = "requester"
  })
}

resource "aws_vpc_peering_connection_accepter" "ap_southeast_from_eu_west" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.ap_southeast_1

  vpc_peering_connection_id = aws_vpc_peering_connection.eu_west_to_ap_southeast[0].id
  auto_accept               = true

  tags = merge(local.common_tags, {
    Name = "ovm-scale-peer-euwest1-apsoutheast1-${local.unique_suffix}"
    Side = "accepter"
  })
}

# Routes for eu-west-1 → ap-southeast-1
resource "aws_route" "eu_west_to_ap_southeast_public" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.eu_west_1

  route_table_id            = module.aws_eu_west_1[0].public_route_table_id
  destination_cidr_block    = module.aws_ap_southeast_1[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.eu_west_to_ap_southeast[0].id

  depends_on = [aws_vpc_peering_connection_accepter.ap_southeast_from_eu_west]
}

resource "aws_route" "eu_west_to_ap_southeast_private" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.eu_west_1

  route_table_id            = module.aws_eu_west_1[0].private_route_table_id
  destination_cidr_block    = module.aws_ap_southeast_1[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.eu_west_to_ap_southeast[0].id

  depends_on = [aws_vpc_peering_connection_accepter.ap_southeast_from_eu_west]
}

# Routes for ap-southeast-1 → eu-west-1
resource "aws_route" "ap_southeast_to_eu_west_public" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.ap_southeast_1

  route_table_id            = module.aws_ap_southeast_1[0].public_route_table_id
  destination_cidr_block    = module.aws_eu_west_1[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.eu_west_to_ap_southeast[0].id

  depends_on = [aws_vpc_peering_connection_accepter.ap_southeast_from_eu_west]
}

resource "aws_route" "ap_southeast_to_eu_west_private" {
  count    = local.enable_aws ? 1 : 0
  provider = aws.ap_southeast_1

  route_table_id            = module.aws_ap_southeast_1[0].private_route_table_id
  destination_cidr_block    = module.aws_eu_west_1[0].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.eu_west_to_ap_southeast[0].id

  depends_on = [aws_vpc_peering_connection_accepter.ap_southeast_from_eu_west]
}
