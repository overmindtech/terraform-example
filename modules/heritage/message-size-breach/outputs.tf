output "sqs_queue_url" {
  description = "URL of the SQS queue for image processing"
  value       = aws_sqs_queue.image_processing_queue.url
}

output "sqs_queue_arn" {
  description = "ARN of the SQS queue for image processing"
  value       = aws_sqs_queue.image_processing_queue.arn
}

output "sqs_queue_name" {
  description = "Name of the SQS queue for image processing"
  value       = aws_sqs_queue.image_processing_queue.name
}

output "lambda_function_name" {
  description = "Name of the Lambda function for image processing"
  value       = aws_lambda_function.image_processor.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function for image processing"
  value       = aws_lambda_function.image_processor.arn
}


output "dlq_url" {
  description = "URL of the Dead Letter Queue"
  value       = aws_sqs_queue.image_processing_dlq.url
}

output "dlq_arn" {
  description = "ARN of the Dead Letter Queue"
  value       = aws_sqs_queue.image_processing_dlq.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for Lambda"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "lambda_errors_alarm_name" {
  description = "Name of the CloudWatch alarm for Lambda errors"
  value       = aws_cloudwatch_metric_alarm.lambda_errors.alarm_name
}

output "sqs_queue_depth_alarm_name" {
  description = "Name of the CloudWatch alarm for SQS queue depth"
  value       = aws_cloudwatch_metric_alarm.sqs_queue_depth.alarm_name
}

# Critical configuration outputs for risk analysis
output "max_message_size" {
  description = "Maximum message size configured for SQS queue (in bytes)"
  value       = var.max_message_size
}

output "batch_size" {
  description = "Batch size configured for Lambda processing"
  value       = var.batch_size
}

output "total_batch_size_bytes" {
  description = "Total batch size in bytes (max_message_size × batch_size)"
  value       = var.max_message_size * var.batch_size
}

output "lambda_payload_limit_bytes" {
  description = "Lambda payload limit for SQS asynchronous invocations (256KB) per AWS Lambda Limits Documentation"
  value       = 262144
}

output "payload_limit_exceeded" {
  description = "Whether the total batch size exceeds Lambda payload limit"
  value       = (var.max_message_size * var.batch_size) > 262144
}

output "risk_assessment" {
  description = "Risk assessment based on configuration"
  value = (var.max_message_size * var.batch_size) > 262144 ? {
    risk_level  = "CRITICAL"
    message     = "Batch size will exceed Lambda payload limit. Lambda invocations will fail."
    impact      = "Complete processing pipeline failure"
    cost_impact = "Exponential cost increase from failed invocations"
    } : {
    risk_level  = "LOW"
    message     = "Configuration is within safe limits"
    impact      = "No expected issues"
    cost_impact = "Normal operational costs"
  }
}
