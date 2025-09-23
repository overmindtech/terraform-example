# outputs.tf
# Outputs for the scenarios module

# Memory optimization demo outputs
output "memory_optimization_demo_status" {
  description = "Status and analysis of the memory optimization demo"
  value       = var.enable_memory_optimization_demo ? module.memory_optimization.demo_status : null
}

output "memory_optimization_demo_url" {
  description = "URL to access the memory optimization demo application"
  value       = var.enable_memory_optimization_demo ? module.memory_optimization.alb_url : null
}

output "memory_optimization_demo_instructions" {
  description = "Instructions for running the memory optimization demo"
  value       = var.enable_memory_optimization_demo ? module.memory_optimization.instructions : null
}

output "memory_optimization_cost_analysis" {
  description = "Cost analysis for the memory optimization scenario"
  value       = var.enable_memory_optimization_demo ? module.memory_optimization.cost_analysis : null
}

# VPC information (useful for other integrations)
output "vpc_id" {
  description = "ID of the VPC created for scenarios"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnets
}