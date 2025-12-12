locals {
  enable_signals_monitoring_vpc = var.enable_api_access
}

data "aws_availability_zones" "available" {
  state = "available"
}

# ------------------------------------------------------------------------------
# Monitoring VPC (peered) - represents a shared services / monitoring network
# ------------------------------------------------------------------------------

resource "aws_vpc" "monitoring" {
  count = local.enable_signals_monitoring_vpc ? 1 : 0

  cidr_block           = "10.50.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "monitoring-${var.example_env}"
    Environment = var.example_env
    Purpose     = "signals-demo-monitoring"
  }
}

resource "aws_subnet" "monitoring_a" {
  count = local.enable_signals_monitoring_vpc ? 1 : 0

  vpc_id            = aws_vpc.monitoring[0].id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = "10.50.101.0/24"

  tags = {
    Name        = "monitoring-a-${var.example_env}"
    Environment = var.example_env
  }
}

resource "aws_subnet" "monitoring_b" {
  count = local.enable_signals_monitoring_vpc ? 1 : 0

  vpc_id            = aws_vpc.monitoring[0].id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block        = "10.50.102.0/24"

  tags = {
    Name        = "monitoring-b-${var.example_env}"
    Environment = var.example_env
  }
}

resource "aws_route_table" "monitoring" {
  count = local.enable_signals_monitoring_vpc ? 1 : 0

  vpc_id = aws_vpc.monitoring[0].id

  tags = {
    Name        = "monitoring-rt-${var.example_env}"
    Environment = var.example_env
  }
}

resource "aws_route_table_association" "monitoring_a" {
  count = local.enable_signals_monitoring_vpc ? 1 : 0

  subnet_id      = aws_subnet.monitoring_a[0].id
  route_table_id = aws_route_table.monitoring[0].id
}

resource "aws_route_table_association" "monitoring_b" {
  count = local.enable_signals_monitoring_vpc ? 1 : 0

  subnet_id      = aws_subnet.monitoring_b[0].id
  route_table_id = aws_route_table.monitoring[0].id
}

# ------------------------------------------------------------------------------
# VPC peering + routes
# ------------------------------------------------------------------------------

resource "aws_vpc_peering_connection" "monitoring_to_baseline" {
  count = local.enable_signals_monitoring_vpc ? 1 : 0

  vpc_id      = module.baseline.vpc_id
  peer_vpc_id = aws_vpc.monitoring[0].id
  auto_accept = true

  tags = {
    Name        = "monitoring-to-baseline-${var.example_env}"
    Environment = var.example_env
    Purpose     = "signals-demo-peering"
  }
}

resource "aws_route" "monitoring_to_baseline" {
  count = local.enable_signals_monitoring_vpc ? 1 : 0

  route_table_id            = aws_route_table.monitoring[0].id
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.monitoring_to_baseline[0].id
}

resource "aws_route" "baseline_to_monitoring" {
  for_each = local.enable_signals_monitoring_vpc ? toset(module.baseline.public_route_table_ids) : toset([])

  route_table_id            = each.value
  destination_cidr_block    = "10.50.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.monitoring_to_baseline[0].id
}

# ------------------------------------------------------------------------------
# Internal NLB in monitoring VPC - target health is our AWS-native proof
# ------------------------------------------------------------------------------

resource "aws_lb" "monitoring_internal" {
  count = local.enable_signals_monitoring_vpc ? 1 : 0

  name               = "mon-internal-${var.example_env}"
  internal           = true
  load_balancer_type = "network"
  subnets = [
    aws_subnet.monitoring_a[0].id,
    aws_subnet.monitoring_b[0].id
  ]

  tags = {
    Name        = "monitoring-internal-nlb-${var.example_env}"
    Environment = var.example_env
    Purpose     = "signals-demo-health-proof"
  }
}

resource "aws_lb_target_group" "api_health" {
  count = local.enable_signals_monitoring_vpc ? 1 : 0

  name        = "api-health-${var.example_env}"
  port        = 9090
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.monitoring[0].id

  health_check {
    protocol = "TCP"
    port     = "traffic-port"
  }

  tags = {
    Name        = "api-health-tg-${var.example_env}"
    Environment = var.example_env
    Purpose     = "signals-demo-health-proof"
  }
}

resource "aws_lb_listener" "monitoring_internal_9090" {
  count = local.enable_signals_monitoring_vpc ? 1 : 0

  load_balancer_arn = aws_lb.monitoring_internal[0].arn
  port              = 9090
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_health[0].arn
  }
}

resource "aws_lb_target_group_attachment" "api_server_ip" {
  count = local.enable_signals_monitoring_vpc ? 1 : 0

  target_group_arn = aws_lb_target_group.api_health[0].arn
  target_id        = module.api_access[0].api_server_private_ip
  port             = 9090

  # If the target IP is not in the target group's VPC CIDR, AWS requires this.
  availability_zone = "all"
}


