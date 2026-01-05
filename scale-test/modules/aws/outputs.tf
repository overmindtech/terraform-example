# =============================================================================
# AWS Module Outputs
# Scale Testing Infrastructure for Overmind
# =============================================================================

# -----------------------------------------------------------------------------
# Network Outputs
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "security_group_ids" {
  description = "IDs of shared security groups"
  value       = aws_security_group.shared[*].id
}

# -----------------------------------------------------------------------------
# Compute Outputs
# -----------------------------------------------------------------------------

output "ec2_instance_ids" {
  description = "IDs of EC2 instances"
  value       = var.enable_ec2 ? aws_instance.scale_test[*].id : []
}

output "lambda_function_arns" {
  description = "ARNs of Lambda functions"
  value       = var.enable_lambda ? aws_lambda_function.scale_test[*].arn : []
}

output "lambda_function_names" {
  description = "Names of Lambda functions"
  value       = var.enable_lambda ? aws_lambda_function.scale_test[*].function_name : []
}

# -----------------------------------------------------------------------------
# Messaging Outputs
# -----------------------------------------------------------------------------

output "sqs_queue_arns" {
  description = "ARNs of SQS queues"
  value       = aws_sqs_queue.scale_test[*].arn
}

output "sqs_queue_urls" {
  description = "URLs of SQS queues"
  value       = aws_sqs_queue.scale_test[*].url
}

output "sns_topic_arns" {
  description = "ARNs of SNS topics"
  value       = aws_sns_topic.scale_test[*].arn
}

# -----------------------------------------------------------------------------
# Storage Outputs
# -----------------------------------------------------------------------------

output "s3_bucket_arns" {
  description = "ARNs of S3 buckets"
  value       = aws_s3_bucket.scale_test[*].arn
}

output "s3_bucket_names" {
  description = "Names of S3 buckets"
  value       = aws_s3_bucket.scale_test[*].bucket
}

output "ssm_parameter_names" {
  description = "Names of SSM parameters"
  value       = aws_ssm_parameter.scale_test[*].name
}

# -----------------------------------------------------------------------------
# IAM Outputs
# -----------------------------------------------------------------------------

output "lambda_role_arns" {
  description = "ARNs of Lambda execution roles"
  value       = aws_iam_role.lambda_execution[*].arn
}

output "ec2_instance_profile_arn" {
  description = "ARN of EC2 instance profile"
  value       = aws_iam_instance_profile.ec2.arn
}

# -----------------------------------------------------------------------------
# Summary Output
# -----------------------------------------------------------------------------

output "resource_summary" {
  description = "Summary of resources created in this region"
  value = {
    region = var.region
    counts = {
      vpc               = 1
      subnets           = length(aws_subnet.public) + length(aws_subnet.private)
      security_groups   = length(aws_security_group.shared)
      ec2_instances     = var.enable_ec2 ? length(aws_instance.scale_test) : 0
      lambda_functions  = var.enable_lambda ? length(aws_lambda_function.scale_test) : 0
      sqs_queues        = length(aws_sqs_queue.scale_test)
      sqs_dlqs          = length(aws_sqs_queue.dlq)
      sns_topics        = length(aws_sns_topic.scale_test)
      s3_buckets        = length(aws_s3_bucket.scale_test)
      ssm_parameters    = length(aws_ssm_parameter.scale_test) + length(aws_ssm_parameter.secure)
      iam_roles         = length(aws_iam_role.lambda_execution) + 1 # +1 for EC2 role
      cloudwatch_groups = length(aws_cloudwatch_log_group.scale_test) + (var.enable_lambda ? length(aws_cloudwatch_log_group.lambda) : 0)
    }
  }
}

