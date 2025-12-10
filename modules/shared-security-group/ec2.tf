# ec2.tf
# API Server Instance

resource "aws_instance" "api_server" {
  count = var.enabled ? 1 : 0

  ami           = var.ami_id
  instance_type = "t3.nano"

  subnet_id                   = var.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.internet_access[0].id]
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd

    cat > /var/www/html/health <<'HEALTH'
    OK
    HEALTH

    cat > /var/www/html/index.html <<'INDEX'
    <!DOCTYPE html>
    <html>
    <head>
        <title>API Server</title>
        <style>
            body { font-family: system-ui, sans-serif; margin: 40px; background: #0f172a; color: #e2e8f0; }
            .container { max-width: 600px; margin: 0 auto; }
            h1 { color: #38bdf8; }
            .status { background: #1e293b; padding: 20px; border-radius: 8px; border-left: 4px solid #22c55e; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>API Server</h1>
            <div class="status">
                <strong>Status:</strong> Running<br>
                <strong>Team:</strong> Platform<br>
                <strong>Managed By:</strong> Terraform
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
    Name = "api-server"
    Team = "platform"
  })
}

