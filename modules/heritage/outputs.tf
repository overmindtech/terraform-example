# outputs.tf
# Outputs for the heritage module

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

# Message size limit breach demo outputs
output "message_size_breach_demo_status" {
  description = "Status and analysis of the message size limit breach demo"
  value       = length(module.message_size_breach) > 0 ? module.message_size_breach[0].risk_assessment : null
}

output "message_size_breach_sqs_queue_url" {
  description = "URL of the SQS queue for the message size breach demo"
  value       = length(module.message_size_breach) > 0 ? module.message_size_breach[0].sqs_queue_url : null
}

output "message_size_breach_lambda_function_name" {
  description = "Name of the Lambda function for the message size breach demo"
  value       = length(module.message_size_breach) > 0 ? module.message_size_breach[0].lambda_function_name : null
}

output "message_size_breach_payload_analysis" {
  description = "Analysis of payload size vs Lambda limits"
  value = length(module.message_size_breach) > 0 ? {
    max_message_size           = module.message_size_breach[0].max_message_size
    batch_size                 = module.message_size_breach[0].batch_size
    total_batch_size_bytes     = module.message_size_breach[0].total_batch_size_bytes
    lambda_payload_limit_bytes = module.message_size_breach[0].lambda_payload_limit_bytes
    payload_limit_exceeded     = module.message_size_breach[0].payload_limit_exceeded
  } : null
}

