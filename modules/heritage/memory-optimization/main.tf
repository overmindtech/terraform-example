# main.tf
# Following guide.md requirements for memory optimization demo
# This creates a self-contained module showing how memory reduction breaks Java apps

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Generate random suffix for resource uniqueness
resource "random_id" "suffix" {
  count       = var.enabled ? 1 : 0
  byte_length = 4
}

# Data sources for VPC configuration
data "aws_vpc" "default" {
  count   = var.enabled && var.use_default_vpc ? 1 : 0
  default = true
}

data "aws_subnets" "default" {
  count = var.enabled && var.use_default_vpc ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

data "aws_availability_zones" "available" {
  count = var.enabled ? 1 : 0
  state = "available"
}

# Create standalone VPC if needed
resource "aws_vpc" "standalone" {
  count                = var.enabled && var.create_standalone_vpc ? 1 : 0
  cidr_block          = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "standalone" {
  count  = var.enabled && var.create_standalone_vpc ? 1 : 0
  vpc_id = aws_vpc.standalone[0].id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

resource "aws_subnet" "standalone" {
  count                   = var.enabled && var.create_standalone_vpc ? 2 : 0
  vpc_id                  = aws_vpc.standalone[0].id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available[0].names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-subnet-${count.index + 1}"
  })
}

resource "aws_route_table" "standalone" {
  count  = var.enabled && var.create_standalone_vpc ? 1 : 0
  vpc_id = aws_vpc.standalone[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.standalone[0].id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rt"
  })
}

resource "aws_route_table_association" "standalone" {
  count          = var.enabled && var.create_standalone_vpc ? 2 : 0
  subnet_id      = aws_subnet.standalone[count.index].id
  route_table_id = aws_route_table.standalone[0].id
}

# Local calculations and configurations
locals {
  # Resource naming with random suffix (shortened for AWS limits)
  random_suffix = var.enabled ? random_id.suffix[0].hex : ""
  name_prefix   = "${substr(var.name_prefix, 0, 10)}-${local.random_suffix}"

  # VPC configuration based on mode
  vpc_id = var.enabled ? (
    var.use_default_vpc ? data.aws_vpc.default[0].id :
    var.create_standalone_vpc ? aws_vpc.standalone[0].id :
    var.vpc_id
  ) : null

  subnet_ids = var.enabled ? (
    var.use_default_vpc ? data.aws_subnets.default[0].ids :
    var.create_standalone_vpc ? aws_subnet.standalone[*].id :
    var.subnet_ids
  ) : []

  # Cost calculations (realistic AWS Fargate pricing)
  cost_per_gb_month = 50
  current_memory_gb = var.container_memory / 1024
  current_cost_month = local.current_memory_gb * var.number_of_containers * local.cost_per_gb_month
  
  # The "optimized" memory that would break everything
  optimized_memory = 1024
  optimized_memory_gb = local.optimized_memory / 1024
  optimized_cost_month = local.optimized_memory_gb * var.number_of_containers * local.cost_per_gb_month
  
  monthly_savings = local.current_cost_month - local.optimized_cost_month

  # The critical calculation: Will this work?
  java_heap_mb = 1536  # -Xmx1536m configured in the application
  java_overhead_mb = 256  # Metaspace + OS overhead
  required_memory_mb = local.java_heap_mb + local.java_overhead_mb
  will_it_work = var.container_memory >= local.required_memory_mb

  # Common tags for all resources (AWS compliant)
  common_tags = {
    Environment = "demo"
    Project     = "memory-optimization"
    Scenario    = "cost-reduction"
    CreatedBy   = "terraform"
    Purpose     = "production-optimization"
    
    # Context tags (AWS compliant format)
    MemoryMB           = tostring(var.container_memory)
    JavaHeapMB         = tostring(local.java_heap_mb)
    RequiredMemoryMB   = tostring(local.required_memory_mb)
    OptimizationWorks  = tostring(local.will_it_work)
    DaysUntilBF        = tostring(var.days_until_black_friday)
    RiskLevel          = local.will_it_work ? "low" : "high"
  }
}