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
  scenario_combined_network = var.scenario == "combined_network"
}

# --- VPC Peering DNS Changes (from vpc_peering_change) ---

resource "aws_vpc_peering_connection_options" "combined_dns_us_east_to_us_west_req" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.us_east_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_us_west.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "combined_dns_us_east_to_us_west_acc" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.us_west_2

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_us_west.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "combined_dns_us_east_to_eu_west_req" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.us_east_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_eu_west.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "combined_dns_us_east_to_eu_west_acc" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.eu_west_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_eu_west.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "combined_dns_us_east_to_ap_southeast_req" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.us_east_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_ap_southeast.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "combined_dns_us_east_to_ap_southeast_acc" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.ap_southeast_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_ap_southeast.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "combined_dns_us_west_to_eu_west_req" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.us_west_2

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_eu_west.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "combined_dns_us_west_to_eu_west_acc" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.eu_west_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_eu_west.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "combined_dns_us_west_to_ap_southeast_req" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.us_west_2

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_ap_southeast.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "combined_dns_us_west_to_ap_southeast_acc" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.ap_southeast_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_ap_southeast.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "combined_dns_eu_west_to_ap_southeast_req" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.eu_west_1

  vpc_peering_connection_id = aws_vpc_peering_connection.eu_west_to_ap_southeast.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "combined_dns_eu_west_to_ap_southeast_acc" {
  count    = local.scenario_combined_network ? 1 : 0
  provider = aws.ap_southeast_1

  vpc_peering_connection_id = aws_vpc_peering_connection.eu_west_to_ap_southeast.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

# --- Shared Security Group SSH Open (from shared_sg_open) ---

resource "aws_security_group_rule" "combined_sg_open_us_east_1" {
  count = local.scenario_combined_network ? 1 : 0

  provider          = aws.us_east_1
  security_group_id = module.aws_us_east_1.high_fanout_sg_id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "COMBINED SCENARIO: SSH open on shared SG + VPC peering DNS"
}

resource "aws_security_group_rule" "combined_sg_open_us_west_2" {
  count = local.scenario_combined_network ? 1 : 0

  provider          = aws.us_west_2
  security_group_id = module.aws_us_west_2.high_fanout_sg_id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "COMBINED SCENARIO: SSH open on shared SG + VPC peering DNS"
}

resource "aws_security_group_rule" "combined_sg_open_eu_west_1" {
  count = local.scenario_combined_network ? 1 : 0

  provider          = aws.eu_west_1
  security_group_id = module.aws_eu_west_1.high_fanout_sg_id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "COMBINED SCENARIO: SSH open on shared SG + VPC peering DNS"
}

resource "aws_security_group_rule" "combined_sg_open_ap_southeast_1" {
  count = local.scenario_combined_network ? 1 : 0

  provider          = aws.ap_southeast_1
  security_group_id = module.aws_ap_southeast_1.high_fanout_sg_id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "COMBINED SCENARIO: SSH open on shared SG + VPC peering DNS"
}

# -----------------------------------------------------------------------------
# Scenario: combined_all
# Combines ALL high-fanout scenarios (except central_s3 which times out)
# - vpc_peering_change: Modify all 6 VPC peerings
# - shared_sg_open: Open SSH on all shared SGs
# - central_sns_change: Modify central SNS policy
# Expected Blast Radius: 1,500-2,000 items at 25x
# -----------------------------------------------------------------------------

locals {
  scenario_combined_all = var.scenario == "combined_all"
}

# --- VPC Peering DNS Changes ---

resource "aws_vpc_peering_connection_options" "all_dns_us_east_to_us_west_req" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.us_east_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_us_west.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "all_dns_us_east_to_us_west_acc" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.us_west_2

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_us_west.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "all_dns_us_east_to_eu_west_req" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.us_east_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_eu_west.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "all_dns_us_east_to_eu_west_acc" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.eu_west_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_eu_west.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "all_dns_us_east_to_ap_southeast_req" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.us_east_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_ap_southeast.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "all_dns_us_east_to_ap_southeast_acc" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.ap_southeast_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_east_to_ap_southeast.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "all_dns_us_west_to_eu_west_req" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.us_west_2

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_eu_west.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "all_dns_us_west_to_eu_west_acc" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.eu_west_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_eu_west.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "all_dns_us_west_to_ap_southeast_req" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.us_west_2

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_ap_southeast.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "all_dns_us_west_to_ap_southeast_acc" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.ap_southeast_1

  vpc_peering_connection_id = aws_vpc_peering_connection.us_west_to_ap_southeast.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "all_dns_eu_west_to_ap_southeast_req" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.eu_west_1

  vpc_peering_connection_id = aws_vpc_peering_connection.eu_west_to_ap_southeast.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "all_dns_eu_west_to_ap_southeast_acc" {
  count    = local.scenario_combined_all ? 1 : 0
  provider = aws.ap_southeast_1

  vpc_peering_connection_id = aws_vpc_peering_connection.eu_west_to_ap_southeast.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

# --- Shared Security Group SSH Open ---

resource "aws_security_group_rule" "all_sg_open_us_east_1" {
  count = local.scenario_combined_all ? 1 : 0

  provider          = aws.us_east_1
  security_group_id = module.aws_us_east_1.high_fanout_sg_id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "COMBINED ALL: SSH + VPC peering + SNS"
}

resource "aws_security_group_rule" "all_sg_open_us_west_2" {
  count = local.scenario_combined_all ? 1 : 0

  provider          = aws.us_west_2
  security_group_id = module.aws_us_west_2.high_fanout_sg_id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "COMBINED ALL: SSH + VPC peering + SNS"
}

resource "aws_security_group_rule" "all_sg_open_eu_west_1" {
  count = local.scenario_combined_all ? 1 : 0

  provider          = aws.eu_west_1
  security_group_id = module.aws_eu_west_1.high_fanout_sg_id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "COMBINED ALL: SSH + VPC peering + SNS"
}

resource "aws_security_group_rule" "all_sg_open_ap_southeast_1" {
  count = local.scenario_combined_all ? 1 : 0

  provider          = aws.ap_southeast_1
  security_group_id = module.aws_ap_southeast_1.high_fanout_sg_id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "COMBINED ALL: SSH + VPC peering + SNS"
}

# --- Central SNS Policy Change ---

resource "aws_sns_topic_policy" "combined_all_central" {
  count = local.scenario_combined_all ? 1 : 0

  provider = aws.us_east_1
  arn      = aws_sns_topic.central.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "CombinedAllScenarioPolicy"
    Statement = [
      {
        Sid    = "AllowCrossRegionSQS"
        Effect = "Allow"
        Principal = {
          Service = "sqs.amazonaws.com"
        }
        Action   = "sns:Subscribe"
        Resource = aws_sns_topic.central.arn
      },
      {
        Sid       = "CombinedAllRestrictPublish"
        Effect    = "Deny"
        Principal = "*"
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.central.arn
        Condition = {
          StringNotEquals = {
            "aws:PrincipalAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

