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
#
# The CIDR scoped here is not just "internal service mesh" - port 9090 is the
# regulated transaction feed consumed by the fraud-detection service across the
# VPC peering connection (see fraud-detection VPC below). var.internal_cidr is
# deliberately scoped to exactly cover both the core VPC and the peered
# fraud-detection VPC's CIDR range. Narrowing it to only the core VPC looks like
# routine hardening but silently drops the one private, compliant path that
# range of regulated data has out of this VPC. See
# .overmind/knowledge/cross-vpc-regulated-feed.md for why this scoping exists.
resource "aws_security_group" "internal_services" {
  name = "internal-services"
  # NOTE: this field is immutable in AWS (any change forces a full SG
  # replace, which collides with create_before_destroy below since the
  # name is unchanged). Convey context via the comment above, the ingress
  # rule descriptions, and the ComplianceGate tag instead.
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
    description = "Regulated transaction feed - consumed by fraud-detection service (PCI scope, cross-VPC peering only)"
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
    ComplianceGate  = "pci-transaction-feed-port-9090"
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
    Name               = "production-api-server"
    Environment        = "production"
    Service            = "core-api"
    Team               = "platform"
    OnCall             = "platform-oncall@company.com"
    CostCenter         = "engineering"
    EmitsRegulatedData = "pci-transaction-feed-port-9090"
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
# RENAMES - the fraud-detection reframe renamed several resources that were
# previously named as generic "monitoring" infrastructure. These moved blocks
# tell Terraform this is an in-place rename, not a destroy+recreate, for any
# state that still has the pre-reframe names.
#------------------------------------------------------------------------------

moved {
  from = aws_vpc.monitoring
  to   = aws_vpc.fraud_detection
}

moved {
  from = aws_subnet.monitoring_a
  to   = aws_subnet.fraud_detection_a
}

moved {
  from = aws_subnet.monitoring_b
  to   = aws_subnet.fraud_detection_b
}

moved {
  from = aws_route_table.monitoring
  to   = aws_route_table.fraud_detection
}

moved {
  from = aws_route_table_association.monitoring_a
  to   = aws_route_table_association.fraud_detection_a
}

moved {
  from = aws_route_table_association.monitoring_b
  to   = aws_route_table_association.fraud_detection_b
}

moved {
  from = aws_vpc_peering_connection.monitoring_to_baseline
  to   = aws_vpc_peering_connection.fraud_detection_to_core
}

moved {
  from = aws_route.monitoring_to_baseline
  to   = aws_route.fraud_detection_to_core
}

moved {
  from = aws_route.baseline_to_monitoring
  to   = aws_route.core_to_fraud_detection
}

moved {
  from = aws_lb.monitoring_internal
  to   = aws_lb.fraud_ingest
}

moved {
  from = aws_lb_target_group.api_health
  to   = aws_lb_target_group.txn_feed
}

moved {
  from = aws_lb_listener.monitoring_internal_9090
  to   = aws_lb_listener.fraud_ingest_9090
}

moved {
  from = aws_lb_target_group_attachment.api_server_ip
  to   = aws_lb_target_group_attachment.core_api_feed
}

#------------------------------------------------------------------------------
# FRAUD-DETECTION VPC (peered) - regulated environment owned by the Risk team
# This is the "needle in the haystack" - a live, cross-VPC dependency that is
# NOT wired up via any Terraform reference (no depends_on, no interpolated
# attribute) between this VPC and the internal-services security group above.
# It only exists as a real network path: peering connection + route + NLB
# target health. Narrowing internal_cidr on the core side silently breaks the
# regulated feed into this VPC, and nothing in a Terraform plan for that
# change would ever mention this VPC, this team, or this data classification.
#------------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "fraud_detection" {
  cidr_block           = "10.50.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name               = "fraud-detection-${var.example_env}"
    Environment        = var.example_env
    Purpose            = "signals-demo-fraud-detection"
    Team               = "risk"
    Owner              = "risk-team"
    OnCall             = "risk-oncall@example.com"
    DataClassification = "regulated-pci"
    Compliance         = "PCI-DSS"
  }
}

resource "aws_subnet" "fraud_detection_a" {
  vpc_id            = aws_vpc.fraud_detection.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = "10.50.101.0/24"

  tags = {
    Name        = "fraud-detection-a-${var.example_env}"
    Environment = var.example_env
    Team        = "risk"
  }
}

resource "aws_subnet" "fraud_detection_b" {
  vpc_id            = aws_vpc.fraud_detection.id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block        = "10.50.102.0/24"

  tags = {
    Name        = "fraud-detection-b-${var.example_env}"
    Environment = var.example_env
    Team        = "risk"
  }
}

resource "aws_route_table" "fraud_detection" {
  vpc_id = aws_vpc.fraud_detection.id

  tags = {
    Name        = "fraud-detection-rt-${var.example_env}"
    Environment = var.example_env
    Team        = "risk"
  }
}

resource "aws_route_table_association" "fraud_detection_a" {
  subnet_id      = aws_subnet.fraud_detection_a.id
  route_table_id = aws_route_table.fraud_detection.id
}

resource "aws_route_table_association" "fraud_detection_b" {
  subnet_id      = aws_subnet.fraud_detection_b.id
  route_table_id = aws_route_table.fraud_detection.id
}

#------------------------------------------------------------------------------
# VPC FLOW LOGS - required audit control for the regulated VPC
#------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "fraud_detection_flow_logs" {
  name              = "/vpc/flow-logs/fraud-detection-${var.example_env}"
  retention_in_days = 90

  tags = {
    Environment = var.example_env
    Team        = "risk"
    Compliance  = "PCI-DSS"
    Purpose     = "regulated-network-audit-trail"
  }
}

resource "aws_iam_role" "fraud_detection_flow_logs" {
  name = "fraud-detection-flow-logs-${var.example_env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.example_env
    Team        = "risk"
  }
}

resource "aws_iam_role_policy" "fraud_detection_flow_logs" {
  name = "fraud-detection-flow-logs-${var.example_env}"
  role = aws_iam_role.fraud_detection_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.fraud_detection_flow_logs.arn}:*"
      }
    ]
  })
}

resource "aws_flow_log" "fraud_detection" {
  vpc_id               = aws_vpc.fraud_detection.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.fraud_detection_flow_logs.arn
  iam_role_arn         = aws_iam_role.fraud_detection_flow_logs.arn

  tags = {
    Name        = "fraud-detection-flow-logs-${var.example_env}"
    Environment = var.example_env
    Team        = "risk"
    Compliance  = "PCI-DSS"
  }
}

#------------------------------------------------------------------------------
# VPC PEERING + ROUTES
#------------------------------------------------------------------------------

resource "aws_vpc_peering_connection" "fraud_detection_to_core" {
  vpc_id      = var.vpc_id
  peer_vpc_id = aws_vpc.fraud_detection.id
  auto_accept = true

  tags = {
    Name        = "fraud-detection-to-core-${var.example_env}"
    Environment = var.example_env
    Purpose     = "signals-demo-regulated-feed-peering"
    Team        = "risk"
    Compliance  = "PCI-DSS"
  }
}

resource "aws_route" "fraud_detection_to_core" {
  route_table_id            = aws_route_table.fraud_detection.id
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.fraud_detection_to_core.id
}

resource "aws_route" "core_to_fraud_detection" {
  count = length(var.public_route_table_ids)

  route_table_id            = var.public_route_table_ids[count.index]
  destination_cidr_block    = "10.50.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.fraud_detection_to_core.id
}

#------------------------------------------------------------------------------
# REGULATED TRANSACTION FEED - NLB in the fraud-detection VPC that pulls the
# feed from the core API across the peering connection. NLB target health is
# our AWS-native, live-only proof that the path is (or isn't) actually open -
# there is no Terraform reference tying this back to internal_cidr.
#------------------------------------------------------------------------------

resource "aws_lb" "fraud_ingest" {
  name               = "fraud-ingest-${var.example_env}"
  internal           = true
  load_balancer_type = "network"
  subnets = [
    aws_subnet.fraud_detection_a.id,
    aws_subnet.fraud_detection_b.id
  ]

  tags = {
    Name        = "fraud-ingest-nlb-${var.example_env}"
    Environment = var.example_env
    Purpose     = "regulated-transaction-feed-ingest"
    Team        = "risk"
    Compliance  = "PCI-DSS"
  }
}

resource "aws_lb_target_group" "txn_feed" {
  name        = "txn-feed-${var.example_env}"
  port        = 9090
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.fraud_detection.id

  health_check {
    protocol = "TCP"
    port     = "traffic-port"
  }

  tags = {
    Name        = "txn-feed-tg-${var.example_env}"
    Environment = var.example_env
    Purpose     = "regulated-transaction-feed-ingest"
    Team        = "risk"
    Compliance  = "PCI-DSS"
  }
}

resource "aws_lb_listener" "fraud_ingest_9090" {
  load_balancer_arn = aws_lb.fraud_ingest.arn
  port              = 9090
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.txn_feed.arn
  }
}

resource "aws_lb_target_group_attachment" "core_api_feed" {
  target_group_arn = aws_lb_target_group.txn_feed.arn
  target_id        = aws_instance.api_server.private_ip
  port             = 9090

  # If the target IP is not in the target group's VPC CIDR, AWS requires this.
  availability_zone = "all"
}

#------------------------------------------------------------------------------
# FRAUD-DETECTION CONSUMER - the actual downstream workload reading the feed,
# owned by the Risk team. Its existence (and the fact that it depends on the
# core VPC's internal_cidr scoping) is invisible from the core team's Terraform
# state - it only shows up by traversing the live peering connection and NLB.
#------------------------------------------------------------------------------

resource "aws_security_group" "fraud_processor" {
  name        = "fraud-processor"
  description = "Fraud-detection transaction consumer - reads the regulated feed from the core API over the peering connection"
  vpc_id      = aws_vpc.fraud_detection.id

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["10.50.0.0/16"]
    description = "Transaction feed from fraud-ingest NLB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name               = "fraud-processor"
    Environment        = var.example_env
    Team               = "risk"
    Owner              = "risk-team"
    Purpose            = "fraud-detection-transaction-consumer"
    DataClassification = "regulated-pci"
    Compliance         = "PCI-DSS"
  }
}

resource "aws_instance" "fraud_processor" {
  ami           = local.ami_id_to_use
  instance_type = "t4g.nano"
  subnet_id     = aws_subnet.fraud_detection_a.id
  vpc_security_group_ids = [
    aws_security_group.fraud_processor.id
  ]

  tags = {
    Name               = "fraud-processor"
    Environment        = var.example_env
    Service            = "fraud-detection"
    Team               = "risk"
    Owner              = "risk-team"
    OnCall             = "risk-oncall@example.com"
    DataClassification = "regulated-pci"
    Compliance         = "PCI-DSS"
  }
}
