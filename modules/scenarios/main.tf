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

  name = "workloads-memory-trick-test"
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
    MemoryMetadata = "1024MB"  # Cosmetic: Just documenting memory change
    MemoryDocumentation = "Reduced to 1024MB for cost optimization"
  }
}

# Memory optimization demo scenario
module "memory_optimization" {
  source = "./memory-optimization"
  
  # Control whether this scenario is enabled
  enabled = var.enable_memory_optimization_demo
  
  # Use the VPC created above instead of default VPC
  use_default_vpc = false
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets
  
  # Demo configuration
  name_prefix = "scenarios-memory-demo"
  container_memory = var.memory_optimization_container_memory
  number_of_containers = var.memory_optimization_container_count
  
  # Context for the demo
  days_until_black_friday = var.days_until_black_friday
  days_since_last_memory_change = 423
}

# Message size limit breach demo scenario
module "message_size_breach" {
  count  = var.enable_message_size_breach_demo ? 1 : 0
  source = "./message-size-breach"
  
  # Demo configuration
  example_env = var.example_env
  
  # The configuration that looks innocent but will break Lambda
  max_message_size = var.message_size_breach_max_size  # 256KB (safe) vs 1MB (dangerous)
  batch_size       = var.message_size_breach_batch_size  # 10 messages
  lambda_timeout   = var.message_size_breach_lambda_timeout
  lambda_memory    = var.message_size_breach_lambda_memory
  retention_days   = var.message_size_breach_retention_days
}

# CloudWatch Dashboard for memory monitoring (cosmetic changes)
resource "aws_cloudwatch_dashboard" "memory_monitoring" {
  dashboard_name = "memory-trick-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "scenarios-memory-trick"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "Memory Usage - 1024MB Limit"
          period  = 300
        }
      }
    ]
  })

  tags = {
    Name = "Memory Monitoring Dashboard"
    MemoryLimit = "1024MB"  # Cosmetic: Just documenting the limit
    MemoryStatus = "Optimized"  # Cosmetic: Status update
    MemoryChange = "Reduced from 2048MB to 1024MB"  # Cosmetic: Change documentation
  }
}

# S3 bucket for memory optimization documentation (cosmetic changes)
resource "aws_s3_bucket" "memory_docs" {
  bucket = "memory-optimization-docs-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "Memory Optimization Documentation"
    MemoryConfiguration = "1024MB"  # Cosmetic: Just documenting configuration
    MemoryOptimization = "Enabled"  # Cosmetic: Status flag
    MemoryReduction = "From 2048MB to 1024MB"  # Cosmetic: Change description
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}
