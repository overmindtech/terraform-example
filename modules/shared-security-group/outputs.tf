# outputs.tf
# Shared Security Group Outputs

output "security_group_id" {
  description = "ID of the internet-access security group"
  value       = var.enabled ? aws_security_group.internet_access[0].id : null
}

output "security_group_name" {
  description = "Name of the internet-access security group"
  value       = var.enabled ? aws_security_group.internet_access[0].name : null
}

output "api_server_instance_id" {
  description = "Instance ID of the API server"
  value       = var.enabled ? aws_instance.api_server[0].id : null
}

output "api_server_public_ip" {
  description = "Public IP of the API server"
  value       = var.enabled ? aws_instance.api_server[0].public_ip : null
}

output "vpc_id" {
  description = "VPC ID (for manual instance creation)"
  value       = var.vpc_id
}

output "subnet_id" {
  description = "Subnet ID (for manual instance creation)"
  value       = var.enabled ? var.public_subnets[0] : null
}

output "ami_id" {
  description = "AMI ID (for manual instance creation)"
  value       = var.ami_id
}

output "manual_instance_command" {
  description = "AWS CLI command to create the manual data-processor instance"
  value = var.enabled ? join(" ", [
    "aws ec2 run-instances",
    "--image-id", var.ami_id,
    "--instance-type t4g.nano",
    "--subnet-id", var.public_subnets[0],
    "--security-group-ids", aws_security_group.internet_access[0].id,
    "--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=data-processor},{Key=Team,Value=data-engineering},{Key=CreatedBy,Value=console}]'",
    "--region", data.aws_region.current.name
  ]) : null
}
