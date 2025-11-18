data "aws_ami" "al2023_arm" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023_arm.id
  instance_type               = "t4g.nano"
  subnet_id                   = values(aws_subnet.private)[0].id
  vpc_security_group_ids      = [aws_security_group.lambda.id]
  iam_instance_profile        = aws_iam_instance_profile.bastion.name
  key_name                    = var.bastion_key_name != "" ? var.bastion_key_name : null
  associate_public_ip_address = false

  metadata_options {
    http_tokens = "required"
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-bastion" })
}

resource "aws_scheduler_schedule" "stop_bastion" {
  name        = "${local.name_prefix}-stop-bastion"
  description = "Ensures the bastion remains stopped outside of ad-hoc sessions"

  schedule_expression = "cron(0 5 * * ? *)"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:${data.aws_partition.current.partition}:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.scheduler.arn
    input = jsonencode({
      InstanceIds = [aws_instance.bastion.id]
    })
  }
}

