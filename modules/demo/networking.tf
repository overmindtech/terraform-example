resource "aws_vpc" "demo" {
  cidr_block           = "10.42.0.0/20"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-vpc" })
}

locals {
  az_map = { for idx, az in local.public_azs : az => idx }
}

resource "aws_subnet" "public" {
  for_each = local.az_map

  vpc_id                  = aws_vpc.demo.id
  availability_zone       = each.key
  cidr_block              = cidrsubnet(aws_vpc.demo.cidr_block, 4, each.value)
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-public-${each.key}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = local.az_map

  vpc_id            = aws_vpc.demo.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(aws_vpc.demo.cidr_block, 4, each.value + 4)

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-private-${each.key}"
    Tier = "private"
  })
}

resource "aws_internet_gateway" "demo" {
  vpc_id = aws_vpc.demo.id

  tags = merge(local.tags, { Name = "${local.name_prefix}-igw" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo.id
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-public-rt" })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.demo.id

  tags = merge(local.tags, { Name = "${local.name_prefix}-private-rt-${each.key}" })
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_security_group" "lambda" {
  name        = "${local.name_prefix}-lambda"
  description = "Allow Lambda egress and intra-VPC access"
  vpc_id      = aws_vpc.demo.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-lambda-sg" })
}

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-aurora"
  description = "Aurora access limited to Lambda"
  vpc_id      = aws_vpc.demo.id

  ingress {
    description     = "Lambda access"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-aurora-sg" })
}

resource "aws_security_group" "endpoints" {
  name        = "${local.name_prefix}-endpoints"
  description = "Interface endpoint access"
  vpc_id      = aws_vpc.demo.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-endpoint-sg" })
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.demo.id
  service_name      = "com.amazonaws.${local.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    [aws_route_table.public.id],
    [for rt in aws_route_table.private : rt.id]
  )

  tags = merge(local.tags, { Name = "${local.name_prefix}-s3-endpoint" })
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.demo.id
  service_name      = "com.amazonaws.${local.region}.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [for rt in aws_route_table.private : rt.id]

  tags = merge(local.tags, { Name = "${local.name_prefix}-ddb-endpoint" })
}

resource "aws_vpc_endpoint" "ssm" {
  for_each = toset(["ssm", "ssmmessages", "ec2messages"])

  vpc_id              = aws_vpc.demo.id
  service_name        = "com.amazonaws.${local.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.private : s.id]
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-${each.key}-endpoint" })
}

