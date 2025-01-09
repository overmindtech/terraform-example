# Get the specific Amazon Linux 2 AMI ID
data "aws_ami" "amazon_linux" {
  most_recent = false

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.20241001.0-x86_64-ebs"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "workloads-${var.example_env}"
  cidr = "10.0.0.0/16"

  default_security_group_egress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "ALL"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  default_security_group_ingress = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 1234
      to_port     = 1234
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  azs             = ["eu-west-2a", "eu-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Launch template that uses the existing AMI
resource "aws_launch_template" "web_lt" {
  name_prefix   = "web-template"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [module.vpc.default_security_group_id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "Hello, World!"
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "web-server"
      Terraform   = "true"
      Environment = "dev"
    }
  }
}

# Auto Scaling Group using the VPC private subnets
resource "aws_autoscaling_group" "web_asg" {
  name                = "web-asg-${var.example_env}"
  desired_capacity    = 3
  max_size           = 5
  min_size           = 1
  vpc_zone_identifier = module.vpc.private_subnets

  # Launch template configuration
  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  # Adding instance refresh configuration - this is the only new change
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup       = 300
    }
  }

  tag {
    key                 = "Environment"
    value              = var.example_env
    propagate_at_launch = true
  }

  tag {
    key                 = "Terraform"
    value              = "true"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [
      tag,
    ]
  }
}

# Trigger for instance refresh - this is the only other new change
resource "null_resource" "trigger_refresh" {
  triggers = {
    refresh_trigger = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOF
      aws autoscaling start-instance-refresh \
        --auto-scaling-group-name ${aws_autoscaling_group.web_asg.name} \
        --region ${data.aws_region.current.name}
    EOF
  }
}

# Data source for current region
data "aws_region" "current" {}