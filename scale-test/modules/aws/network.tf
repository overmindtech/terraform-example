# =============================================================================
# AWS Network Resources
# Scale Testing Infrastructure for Overmind
# =============================================================================
# Creates VPCs, subnets, route tables, internet gateways, and security groups.
# No NAT Gateways for cost savings - using public subnets only.
# =============================================================================

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

# -----------------------------------------------------------------------------
# Internet Gateway
# -----------------------------------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

# -----------------------------------------------------------------------------
# Public Subnets (for EC2 instances - no NAT Gateway needed)
# -----------------------------------------------------------------------------

resource "aws_subnet" "public" {
  count = length(local.azs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-public-${count.index + 1}"
    Type = "public"
  })
}

# -----------------------------------------------------------------------------
# Private Subnets (for Lambda - no NAT, so no external access)
# -----------------------------------------------------------------------------

resource "aws_subnet" "private" {
  count = length(local.azs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 8)
  availability_zone = local.azs[count.index]

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-private-${count.index + 1}"
    Type = "private"
  })
}

# -----------------------------------------------------------------------------
# Route Tables
# -----------------------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  # No routes to internet (no NAT Gateway for cost savings)

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-private-rt"
  })
}

# -----------------------------------------------------------------------------
# Route Table Associations
# -----------------------------------------------------------------------------

resource "aws_route_table_association" "public" {
  count = length(local.azs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(local.azs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# -----------------------------------------------------------------------------
# Security Groups
# -----------------------------------------------------------------------------

resource "aws_security_group" "shared" {
  count = local.regional_count.security_groups

  name        = "${local.name_prefix}-sg-${count.index + 1}"
  description = "Shared security group ${count.index + 1} for scale testing"
  vpc_id      = aws_vpc.main.id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  # Allow inbound from same security group (creates self-referential relationships)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow traffic from same security group"
  }

  # Allow SSH from VPC (stopped instances, so no real access)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "SSH from VPC"
  }

  tags = merge(var.common_tags, {
    Name  = "${local.name_prefix}-sg-${count.index + 1}"
    Index = count.index + 1
  })
}

# -----------------------------------------------------------------------------
# VPC Endpoints (for AWS service access without NAT)
# -----------------------------------------------------------------------------

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-s3-endpoint"
  })
}

