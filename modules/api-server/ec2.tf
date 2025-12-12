# ec2.tf
# API Server EC2 Instance

resource "aws_instance" "api_server" {
  count = var.enabled ? 1 : 0

  ami                  = var.ami_id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.api_server[0].name

  subnet_id                   = var.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.api_server[0].id]
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true

    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-root-volume"
    })
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
set -ex

# Install EPEL for stress-ng and other packages
amazon-linux-extras install epel -y || yum install -y epel-release
yum update -y
yum install -y httpd stress-ng

# Create systemd service for CPU load simulation (70% sustained)
cat > /etc/systemd/system/cpu-load-simulator.service <<'SERVICE'
[Unit]
Description=Simulate 70% CPU load for demo purposes
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/stress-ng --cpu 2 --cpu-load 70
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE

# Enable and start CPU load simulation
systemctl daemon-reload
systemctl enable cpu-load-simulator
systemctl start cpu-load-simulator

cat > /var/www/html/health <<'HEALTH'
OK
HEALTH

cat > /var/www/html/index.html <<'INDEX'
<!DOCTYPE html>
<html>
<head>
    <title>API Server Status</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 40px; background: #1a1a2e; color: #eee; }
        .container { max-width: 800px; margin: 0 auto; }
        h1 { color: #00d9ff; border-bottom: 2px solid #00d9ff; padding-bottom: 10px; }
        .metric { background: #16213e; padding: 20px; margin: 15px 0; border-radius: 8px; border-left: 4px solid #00d9ff; }
        .metric-label { color: #888; font-size: 12px; text-transform: uppercase; }
        .metric-value { font-size: 32px; font-weight: bold; margin: 5px 0; }
        .cpu-bar { height: 20px; background: #0f3460; border-radius: 10px; overflow: hidden; margin-top: 10px; }
        .cpu-fill { height: 100%; background: linear-gradient(90deg, #51cf66, #fcc419, #ff6b6b); width: ${var.typical_cpu_utilization}%; }
        .info { background: #0f3460; padding: 15px; border-radius: 8px; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>API Server Status</h1>
        
        <div class="metric">
            <div class="metric-label">Instance Type</div>
            <div class="metric-value">${var.instance_type}</div>
        </div>

        <div class="metric">
            <div class="metric-label">Current CPU Utilization</div>
            <div class="metric-value">${var.typical_cpu_utilization}%</div>
            <div class="cpu-bar"><div class="cpu-fill"></div></div>
        </div>

        <div class="info">
            <strong>Workload:</strong> ${var.workload_description}
        </div>
    </div>
</body>
</html>
INDEX

systemctl start httpd
systemctl enable httpd
EOF
  )

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-api-server"
  })
}

resource "aws_security_group" "api_server" {
  count = var.enabled ? 1 : 0

  name        = "${local.name_prefix}-api-sg"
  description = "Security group for API server"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb[0].id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "Database access"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.database[0].id]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-api-sg"
  })
}

