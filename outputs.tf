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
