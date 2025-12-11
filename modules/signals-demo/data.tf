data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Use provided subnets or find subnets in the selected VPC
data "aws_subnets" "selected" {
  count = length(var.subnet_ids) == 0 && var.vpc_id != "" ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# Always look up Amazon Linux 2023 ARM64 AMI (required for t4g.nano instance type)
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

locals {
  subnet_ids_to_use = length(var.subnet_ids) > 0 ? var.subnet_ids : (length(data.aws_subnets.selected) > 0 ? data.aws_subnets.selected[0].ids : [])
  # Always use ARM64 AMI for t4g.nano instance type, ignoring provided AMI
  ami_id_to_use     = data.aws_ami.amazon_linux_2023.id
}
