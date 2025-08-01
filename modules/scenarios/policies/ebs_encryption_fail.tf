# Policy Test: EBS Volume Encryption - FAIL Case
# Tests: "EC2 EBS Encryption Enabled" policy
# Expected: Policy should FAIL - volume is not encrypted

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

# FAIL: Unencrypted EBS volume (intentionally insecure for testing)
resource "aws_ebs_volume" "unencrypted_volume" {
  availability_zone = "eu-west-2a"
  size              = 10
  encrypted         = false # Policy should FAIL - INTENTIONALLY INSECURE FOR TESTING
  type              = "gp3"

  tags = {
    Name        = "unencrypted-test-volume"
    Environment = "test"
    Purpose     = "policy-testing"
    TestCase    = "ebs-encryption-fail"
    Warning     = "INTENTIONALLY-INSECURE-FOR-TESTING"
  }
}
