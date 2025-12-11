#------------------------------------------------------------------------------
# SECURITY GROUPS
#------------------------------------------------------------------------------

# Customer-facing API access - FREQUENTLY UPDATED (routine changes)
resource "aws_security_group" "customer_access" {
  name        = "customer-api-access"
  description = "Customer IP whitelist for API access - updated frequently"
  vpc_id      = local.vpc_id_to_use

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
  vpc_id      = local.vpc_id_to_use

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
  ami                    = local.ami_id_to_use
  instance_type          = "t4g.nano"
  subnet_id              = local.subnet_ids_to_use[0]
  vpc_security_group_ids = [
    aws_security_group.customer_access.id,
    aws_security_group.internal_services.id
  ]

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
