output "vpc_id" {
  description = "VPC hosting the demo workload"
  value       = aws_vpc.demo.id
}

output "static_site_bucket" {
  description = "Bucket backing the CloudFront distribution"
  value       = aws_s3_bucket.static_site.bucket
}

output "event_bus_name" {
  description = "Custom EventBridge bus processing asset events"
  value       = aws_cloudwatch_event_bus.pipeline.name
}

output "step_function_arn" {
  description = "Asset processing workflow ARN"
  value       = aws_sfn_state_machine.asset_pipeline.arn
}

