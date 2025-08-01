# Policy Test: Attached EBS Volume Encryption - PASS Case
# Tests: "EC2 Attached EBS Volumes Encrypted at Rest" policy
# Expected: Policy should PASS - attached volume is encrypted

# Get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security group for test instance (restrictive)
resource "aws_security_group" "test_instance_sg" {
  name_prefix = "policy-test-attached-pass-"
  description = "Security group for policy test instance - no inbound access"

  # Allow all outbound traffic for updates/patches
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "policy-test-attached-pass-sg"
    TestCase = "attached-encryption-pass"
  }
}

# PASS: Encrypted EBS volume for attachment
resource "aws_ebs_volume" "encrypted_volume" {
  availability_zone = "eu-west-2a"
  size              = 10
  encrypted         = true  # Policy should PASS
  type              = "gp3"

  tags = {
    Name        = "encrypted-attached-test-volume"
    Environment = "test"
    Purpose     = "policy-testing"
    TestCase    = "attached-encryption-pass"
  }
}

# EC2 instance for attachment testing
resource "aws_instance" "test_instance" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  availability_zone      = "eu-west-2a"
  vpc_security_group_ids = [aws_security_group.test_instance_sg.id]

  # Disable public IP for security
  associate_public_ip_address = false

  # Enable detailed monitoring for security auditing
  monitoring = true

  # Enable EBS optimization for better security posture
  ebs_optimized = true

  # Root block device with encryption
  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 8

    tags = {
      Name = "policy-test-attached-pass-root"
    }
  }

  tags = {
    Name     = "policy-test-attached-pass-instance"
    TestCase = "attached-encryption-pass"
  }
}

# PASS: Encrypted volume attachment
resource "aws_volume_attachment" "encrypted_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.encrypted_volume.id
  instance_id = aws_instance.test_instance.id
}
