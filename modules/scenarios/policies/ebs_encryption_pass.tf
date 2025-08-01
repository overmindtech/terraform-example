# Policy Test: EBS Volume Encryption - PASS Case
# Tests: "EC2 EBS Encryption Enabled" policy
# Expected: Policy should PASS - volume is encrypted

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

# PASS: Encrypted EBS volume
resource "aws_ebs_volume" "encrypted_volume" {
  availability_zone = "eu-west-2a"
  size              = 10
  encrypted         = true  # Policy should PASS
  type              = "gp3" # More secure and performant volume type

  tags = {
    Name        = "encrypted-test-volume"
    Environment = "test"
    Purpose     = "policy-testing"
    TestCase    = "ebs-encryption-pass"
  }
}
