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
