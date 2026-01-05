# =============================================================================
# AWS Module - Main Configuration
# Scale Testing Infrastructure for Overmind
# =============================================================================
# This module creates AWS resources for a single region.
# It is instantiated once per AWS region in the root module.
# =============================================================================

# -----------------------------------------------------------------------------
# Local Variables
# -----------------------------------------------------------------------------

locals {
  # Region-specific resource counts (divide by 4 regions)
  regional_count = {
    for k, v in var.resource_counts : k => ceil(v / 4)
  }

  # Naming prefix for all resources
  name_prefix = "ovm-scale-${var.region}-${var.unique_suffix}"

  # Short region name for resource naming (remove dashes)
  region_short = replace(var.region, "-", "")

  # Subnet CIDR calculations
  # VPC is /16, we create public (/20) and private (/20) subnets
  vpc_cidr_prefix = split(".", var.vpc_cidr)[0]
  vpc_cidr_second = split(".", var.vpc_cidr)[1]

  # Availability zones for the region (use first 2)
  azs = slice(data.aws_availability_zones.available.names, 0, min(2, length(data.aws_availability_zones.available.names)))
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

