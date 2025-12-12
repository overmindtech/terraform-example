# output "terraform_deploy_role" {
#   value = aws_iam_role.deploy_role.arn
# }

# API Server outputs
output "api_server_url" {
  description = "URL to access the API server"
  value       = module.api_server.alb_url
}

output "api_server_instance_id" {
  description = "Instance ID for start/stop commands"
  value       = module.api_server.instance_id
}

# Shared Security Group outputs
output "shared_sg_security_group_id" {
  description = "ID of the internet-access security group (for manual instance creation)"
  value       = module.shared_security_group.security_group_id
}

output "shared_sg_api_server_id" {
  description = "Instance ID of the shared SG demo API server"
  value       = module.shared_security_group.api_server_instance_id
}

output "shared_sg_manual_instance_command" {
  description = "CLI command to create the manual data-processor instance"
  value       = module.shared_security_group.manual_instance_command
}

# ------------------------------------------------------------------------------
# Signals demo (monitoring VPC + NLB health proof)
# ------------------------------------------------------------------------------

output "signals_monitoring_vpc_id" {
  description = "ID of the peered monitoring/shared-services VPC (signals demo)"
  value       = var.enable_api_access ? aws_vpc.monitoring[0].id : null
}

output "signals_vpc_peering_connection_id" {
  description = "VPC peering connection ID between baseline and monitoring VPC (signals demo)"
  value       = var.enable_api_access ? aws_vpc_peering_connection.monitoring_to_baseline[0].id : null
}

output "signals_monitoring_nlb_arn" {
  description = "ARN of the internal NLB in the monitoring VPC (signals demo)"
  value       = var.enable_api_access ? aws_lb.monitoring_internal[0].arn : null
}

output "signals_monitoring_nlb_dns_name" {
  description = "DNS name of the internal NLB in the monitoring VPC (signals demo)"
  value       = var.enable_api_access ? aws_lb.monitoring_internal[0].dns_name : null
}

output "signals_monitoring_target_group_arn" {
  description = "Target group ARN used to health-check the API instance from the monitoring VPC (signals demo)"
  value       = var.enable_api_access ? aws_lb_target_group.api_health[0].arn : null
}
