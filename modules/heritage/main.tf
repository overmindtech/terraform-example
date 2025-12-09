# Memory optimization demo scenario
module "memory_optimization" {
  source = "./memory-optimization"

  # Control whether this scenario is enabled
  enabled = var.enable_memory_optimization_demo

  # Use the VPC created above instead of default VPC
  use_default_vpc = false
  vpc_id          = var.vpc_id
  subnet_ids      = var.public_subnets

  # Demo configuration
  name_prefix          = "scenarios-memory-demo"
  container_memory     = var.memory_optimization_container_memory
  number_of_containers = var.memory_optimization_container_count

  # Context for the demo
  days_until_black_friday       = var.days_until_black_friday
  days_since_last_memory_change = 423
}

# Message size limit breach demo scenario
module "message_size_breach" {
  count  = var.enable_message_size_breach_demo ? 1 : 0
  source = "./message-size-breach"

  # Demo configuration
  example_env = var.example_env

  # The configuration that looks innocent but will break Lambda
  max_message_size = var.message_size_breach_max_size   # 256KB (safe) vs 1MB (dangerous)
  batch_size       = var.message_size_breach_batch_size # 10 messages
  lambda_timeout   = var.message_size_breach_lambda_timeout
  lambda_memory    = var.message_size_breach_lambda_memory
  retention_days   = var.message_size_breach_retention_days
}

