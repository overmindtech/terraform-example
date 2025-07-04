# Get the specific Amazon Linux 2 AMI ID
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  # version 6 is breaking change across multiple AWS module so we pin to < 6.0 see https://github.com/terraform-aws-modules/terraform-aws-ecs/issues/291
  # another pin was added to terraform.tf for the S3 module
  # we expect this to be fixed over the coming weeks, as of 23/6/2025
  version = "< 6.0"

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
