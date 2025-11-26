# ============================================================================
# ⚠️  WARNING: DO NOT MERGE THIS FILE ⚠️
# ============================================================================
# This file exists ONLY to demonstrate the Infracost cost signal integration.
# It creates ~$500/month in AWS resources that serve no purpose.
#
# This should trigger the cost-signals-action and block the PR.
# DELETE THIS BRANCH after the demo!
# ============================================================================

locals {
  enable_cost_demo = true
}

# Demo EC2 instances - ~$500/month total
resource "aws_instance" "cost_demo" {
  count = local.enable_cost_demo ? 4 : 0

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.xlarge" # 4 vCPUs, 16 GB RAM - ~$120/month each

  subnet_id = module.vpc.private_subnets[0]

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }

  tags = {
    Name        = "cost-demo-DO-NOT-MERGE-${count.index}"
    Purpose     = "cost-signal-demo-TEMPORARY"
    Environment = var.example_env
    Warning     = "DELETE-THIS-BRANCH"
  }
}

