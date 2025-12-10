# security-group.tf
# Shared Security Group

resource "aws_security_group" "internet_access" {
  count = var.enabled ? 1 : 0

  name        = "internet-access"
  description = "Allow outbound internet access"
  vpc_id      = var.vpc_id

  # Restrict to API traffic only
  egress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "API outbound traffic only"
  }

  # Allow SSH for management
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # Allow HTTP for health checks
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  tags = merge(local.common_tags, {
    Name    = "internet-access"
    Purpose = "General outbound access"
    Team    = "platform"
  })

  lifecycle {
    create_before_destroy = true
  }
}

