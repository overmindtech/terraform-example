#------------------------------------------------------------------------------
# SECURITY GROUPS
#------------------------------------------------------------------------------

# Customer-facing API access - FREQUENTLY UPDATED (routine changes)
resource "aws_security_group" "customer_access" {
  name        = "customer-api-access"
  description = "Customer IP whitelist for API access - updated frequently"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.customer_cidrs
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [ingress.value.cidr]
      description = ingress.value.name
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name            = "customer-api-access"
    Environment     = "production"
    Team            = "platform"
    Purpose         = "customer-whitelist"
    UpdateFrequency = "high"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Internal service communication - RARELY UPDATED (the needle targets this)
resource "aws_security_group" "internal_services" {
  name        = "internal-services"
  description = "Internal service mesh, monitoring, and health check access - rarely modified"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.internal_cidr]
    description = "Internal HTTPS - monitoring, service mesh, internal tools"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.internal_cidr]
    description = "Health check endpoint"
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.internal_cidr]
    description = "Prometheus metrics scraping"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name            = "internal-services"
    Environment     = "production"
    Team            = "platform"
    Purpose         = "internal-mesh"
    Critical        = "true"
    UpdateFrequency = "low"
  }

  lifecycle {
    create_before_destroy = true
  }
}

#------------------------------------------------------------------------------
# COMPUTE
#------------------------------------------------------------------------------

# Production API server - uses BOTH security groups
resource "aws_instance" "api_server" {
  ami           = local.ami_id_to_use
  instance_type = "t4g.nano"
  subnet_id     = local.subnet_ids_to_use[0]
  vpc_security_group_ids = [
    aws_security_group.customer_access.id,
    aws_security_group.internal_services.id
  ]

  # Deterministic local endpoint so AWS-managed health checks (e.g. NLB target health)
  # can succeed/fail purely due to networking and security group rules.
  user_data = <<-EOF
              #!/bin/bash
              set -euo pipefail

              # Ensure python3 exists (Amazon Linux 2)
              yum install -y python3

              cat >/opt/health_server.py <<'PY'
              from http.server import BaseHTTPRequestHandler, HTTPServer

              class Handler(BaseHTTPRequestHandler):
                  def do_GET(self):
                      if self.path in ("/health", "/healthz", "/"):
                          self.send_response(200)
                          self.send_header("Content-Type", "text/plain")
                          self.end_headers()
                          self.wfile.write(b"ok\n")
                          return
                      self.send_response(404)
                      self.end_headers()

                  def log_message(self, format, *args):
                      # Silence noisy logs in demo environment
                      return

              if __name__ == "__main__":
                  server = HTTPServer(("0.0.0.0", 9090), Handler)
                  server.serve_forever()
              PY

              cat >/etc/systemd/system/health-server.service <<'UNIT'
              [Unit]
              Description=Signals demo health endpoint (port 9090)
              After=network-online.target
              Wants=network-online.target

              [Service]
              Type=simple
              ExecStart=/usr/bin/python3 /opt/health_server.py
              Restart=always
              RestartSec=2

              [Install]
              WantedBy=multi-user.target
              UNIT

              systemctl daemon-reload
              systemctl enable --now health-server.service
              EOF

  user_data_replace_on_change = true

  tags = {
    Name        = "production-api-server"
    Environment = "production"
    Service     = "core-api"
    Team        = "platform"
    OnCall      = "platform-oncall@company.com"
    CostCenter  = "engineering"
  }
}

# Elastic IP for stable public endpoint
resource "aws_eip" "api_server" {
  instance = aws_instance.api_server.id
  domain   = "vpc"

  tags = {
    Name        = "production-api-eip"
    Environment = "production"
    Service     = "core-api"
  }
}

#------------------------------------------------------------------------------
# DNS & HEALTH CHECKS
#------------------------------------------------------------------------------

# Route 53 zone for API domain
resource "aws_route53_zone" "api" {
  name = var.domain

  tags = {
    Environment = "production"
    Purpose     = "api-endpoint"
  }
}

# DNS A record pointing to API server
resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.api.zone_id
  name    = var.domain
  type    = "A"
  ttl     = 300
  records = [aws_eip.api_server.public_ip]
}

# Health check for the API endpoint
resource "aws_route53_health_check" "api" {
  ip_address        = aws_eip.api_server.public_ip
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name        = "production-api-health"
    Environment = "production"
    Service     = "core-api"
  }
}

#------------------------------------------------------------------------------
# ALERTING
#------------------------------------------------------------------------------

# SNS topic for production alerts
resource "aws_sns_topic" "alerts" {
  name = "production-api-alerts"

  tags = {
    Environment = "production"
    Purpose     = "oncall-alerts"
    Severity    = "critical"
  }
}

# Email subscription for alerts
resource "aws_sns_topic_subscription" "oncall_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch alarm for health check failures
resource "aws_cloudwatch_metric_alarm" "api_health" {
  alarm_name          = "production-api-health-check-failed"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "Production API health check failing - pages on-call team"

  dimensions = {
    HealthCheckId = aws_route53_health_check.api.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Environment = "production"
    Service     = "core-api"
    Severity    = "critical"
  }
}

#------------------------------------------------------------------------------
# MONITORING VPC (peered) - represents a shared services / monitoring network
# This is the "needle in the haystack" - the monitoring VPC that health checks
# the API server through the peered connection
#------------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "monitoring" {
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
  vpc_id            = aws_vpc.monitoring.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = "10.50.101.0/24"

  tags = {
    Name        = "monitoring-a-${var.example_env}"
    Environment = var.example_env
  }
}

resource "aws_subnet" "monitoring_b" {
  vpc_id            = aws_vpc.monitoring.id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block        = "10.50.102.0/24"

  tags = {
    Name        = "monitoring-b-${var.example_env}"
    Environment = var.example_env
  }
}

resource "aws_route_table" "monitoring" {
  vpc_id = aws_vpc.monitoring.id

  tags = {
    Name        = "monitoring-rt-${var.example_env}"
    Environment = var.example_env
  }
}

resource "aws_route_table_association" "monitoring_a" {
  subnet_id      = aws_subnet.monitoring_a.id
  route_table_id = aws_route_table.monitoring.id
}

resource "aws_route_table_association" "monitoring_b" {
  subnet_id      = aws_subnet.monitoring_b.id
  route_table_id = aws_route_table.monitoring.id
}

#------------------------------------------------------------------------------
# VPC PEERING + ROUTES
#------------------------------------------------------------------------------

resource "aws_vpc_peering_connection" "monitoring_to_baseline" {
  vpc_id      = var.vpc_id
  peer_vpc_id = aws_vpc.monitoring.id
  auto_accept = true

  tags = {
    Name        = "monitoring-to-baseline-${var.example_env}"
    Environment = var.example_env
    Purpose     = "signals-demo-peering"
  }
}

resource "aws_route" "monitoring_to_baseline" {
  route_table_id            = aws_route_table.monitoring.id
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.monitoring_to_baseline.id
}

resource "aws_route" "baseline_to_monitoring" {
  for_each = length(var.public_route_table_ids) > 0 ? toset(var.public_route_table_ids) : toset([])

  route_table_id            = each.value
  destination_cidr_block    = "10.50.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.monitoring_to_baseline.id
}

#------------------------------------------------------------------------------
# INTERNAL NLB IN MONITORING VPC - target health is our AWS-native proof
#------------------------------------------------------------------------------

resource "aws_lb" "monitoring_internal" {
  name               = "mon-internal-${var.example_env}"
  internal           = true
  load_balancer_type = "network"
  subnets = [
    aws_subnet.monitoring_a.id,
    aws_subnet.monitoring_b.id
  ]

  tags = {
    Name        = "monitoring-internal-nlb-${var.example_env}"
    Environment = var.example_env
    Purpose     = "signals-demo-health-proof"
  }
}

resource "aws_lb_target_group" "api_health" {
  name        = "api-health-${var.example_env}"
  port        = 9090
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.monitoring.id

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
  load_balancer_arn = aws_lb.monitoring_internal.arn
  port              = 9090
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_health.arn
  }
}

resource "aws_lb_target_group_attachment" "api_server_ip" {
  target_group_arn = aws_lb_target_group.api_health.arn
  target_id        = aws_instance.api_server.private_ip
  port             = 9090

  # If the target IP is not in the target group's VPC CIDR, AWS requires this.
  availability_zone = "all"
}
