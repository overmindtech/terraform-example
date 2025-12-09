# networking.tf
# Following guide.md requirements for memory optimization demo
# Create ALB, security groups, target groups with dangerous configurations

# Application Load Balancer
resource "aws_lb" "app" {
  count              = var.enabled ? 1 : 0
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = local.subnet_ids

  enable_deletion_protection = false

  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}-alb"
    Description = "ALB for memory optimization demo - will route to failing containers after memory change"

    # Context tags
    "context:black-friday-traffic" = "10x normal load expected"
    "context:capacity-planning"    = "load balancer configured for high traffic"
  })
}

# Target Group - DANGEROUS CONFIGURATION!
resource "aws_lb_target_group" "app" {
  count       = var.enabled ? 1 : 0
  name        = "${local.name_prefix}-tg"
  port        = var.application_port
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  # CRITICAL RISK: 5 second deregistration = no time for rollback!
  deregistration_delay = var.deregistration_delay

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}-tg"
    Description = "Target group with ${var.deregistration_delay}s deregistration - NO TIME FOR ROLLBACK"

    # Risk warning tags
    "risk:deregistration-delay" = "${var.deregistration_delay}s"
    "risk:rollback-capability"  = "none"
    "risk:black-friday-timing"  = "change ${var.days_until_black_friday} days before peak"
  })
}

# ALB Listener
resource "aws_lb_listener" "app" {
  count             = var.enabled ? 1 : 0
  load_balancer_arn = aws_lb.app[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"

    forward {
      target_group {
        arn = aws_lb_target_group.app[0].arn
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-listener"
  })
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  count       = var.enabled ? 1 : 0
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for ALB - allows public HTTP access"
  vpc_id      = local.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}-alb-sg"
    Description = "ALB security group - public access for Black Friday capacity testing"
  })
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  count       = var.enabled ? 1 : 0
  name        = "${local.name_prefix}-ecs-sg"
  description = "Security group for ECS tasks - allows ALB access"
  vpc_id      = local.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = var.application_port
    to_port         = var.application_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb[0].id]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}-ecs-sg"
    Description = "ECS tasks security group - containers will crash after memory optimization"

    # Warning tags
    "warning:containers-affected" = "${var.number_of_containers} containers"
    "warning:crash-behavior"      = "immediate OOM after memory reduction"
  })
}