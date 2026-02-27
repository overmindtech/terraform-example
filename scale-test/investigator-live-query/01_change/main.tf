provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project   = "investigator-live-query-test"
      ManagedBy = "terraform"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  services = { for i in range(var.service_count) : format("%02d", i) => i }
  healthy  = { for k, v in local.services : k => v if !contains(var.broken_indices, v) }
  broken   = { for k, v in local.services : k => v if contains(var.broken_indices, v) }
  az_a     = data.aws_availability_zones.available.names[0]
  az_b     = data.aws_availability_zones.available.names[1]
}

# =============================================================================
# Shared Infrastructure (identical to 00_setup/)
# =============================================================================

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "ilq-vpc" }
}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = local.az_a

  tags = { Name = "ilq-subnet-a" }
}

resource "aws_subnet" "b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = local.az_b

  tags = { Name = "ilq-subnet-b" }
}

resource "aws_security_group" "shared" {
  name_prefix = "ilq-shared-"
  description = "Shared SG for investigator live query test"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ilq-shared-sg" }
}

resource "aws_route53_zone" "private" {
  name = "internal.test"

  vpc {
    vpc_id = aws_vpc.main.id
  }

  tags = { Name = "ilq-private-zone" }
}

# =============================================================================
# Per-Service Stacks (identical to 00_setup/ — NLBs, TGs, listeners unchanged)
# =============================================================================

resource "aws_lb" "svc" {
  for_each = local.services

  name               = "ilq-svc-${each.key}"
  internal           = true
  load_balancer_type = "network"
  subnets            = [aws_subnet.a.id, aws_subnet.b.id]
  security_groups    = [aws_security_group.shared.id]

  tags = { Name = "ilq-svc-${each.key}" }
}

resource "aws_lb_target_group" "svc" {
  for_each = local.services

  name     = "ilq-svc-${each.key}"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    protocol = "TCP"
  }

  tags = { Name = "ilq-svc-${each.key}" }
}

resource "aws_lb_listener" "svc" {
  for_each = local.services

  load_balancer_arn = aws_lb.svc[each.key].arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.svc[each.key].arn
  }
}

# =============================================================================
# Route53 Records — THIS IS WHERE THE BREAKAGE HAPPENS
#
# Healthy services keep their NLB alias records (no change from setup).
# Broken services switch to hardcoded A records pointing to 10.0.99.X —
# private IPs that don't belong to any resource in this account.
#
# The plan will show:
#   - DESTROY aws_route53_record.svc["03"] (alias record removed)
#   - CREATE  aws_route53_record.svc_dangling["03"] (hardcoded A record)
#
# The hardcoded IPs are invisible to the blast radius. Without live query
# tools the investigator can only see silence. With live query tools it can
# search for resources at those IPs and get an explicit "not found".
# =============================================================================

resource "aws_route53_record" "svc" {
  for_each = local.healthy

  zone_id = aws_route53_zone.private.zone_id
  name    = "svc-${each.key}.internal.test"
  type    = "A"

  alias {
    name                   = aws_lb.svc[each.key].dns_name
    zone_id                = aws_lb.svc[each.key].zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "svc_dangling" {
  for_each = local.broken

  zone_id = aws_route53_zone.private.zone_id
  name    = "svc-${each.key}.internal.test"
  type    = "A"
  ttl     = 60
  records = ["10.0.99.${each.value + 1}"]
}
