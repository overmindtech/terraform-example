# outputs.tf
# Module outputs

output "enabled" {
  description = "Whether this module is enabled"
  value       = var.enabled
}

output "instance_id" {
  description = "Instance ID of the API server"
  value       = var.enabled ? aws_instance.api_server[0].id : null
}

output "public_ip" {
  description = "Public IP of the API server"
  value       = var.enabled ? aws_instance.api_server[0].public_ip : null
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = var.enabled ? aws_lb.api[0].dns_name : null
}

output "alb_url" {
  description = "URL to access the API through the load balancer"
  value       = var.enabled ? "http://${aws_lb.api[0].dns_name}" : null
}

output "health_check_url" {
  description = "URL for health check endpoint"
  value       = var.enabled ? "http://${aws_lb.api[0].dns_name}/health" : null
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarm notifications"
  value       = var.enabled ? aws_sns_topic.alerts[0].arn : null
}

# Analysis outputs (for educational purposes after apply)
output "cpu_analysis" {
  description = "Analysis of CPU behavior for the current instance type"
  value = var.enabled ? {
    instance_type        = var.instance_type
    cpu_model            = local.is_burstable ? "Burstable (credit-based)" : "Unlimited (sustained)"
    baseline_performance = local.is_burstable ? "${local.t3_baseline_percent}% of vCPU" : "100% of vCPU"

    workload_analysis = {
      typical_cpu_usage   = "${var.typical_cpu_utilization}%"
      sustainable         = var.typical_cpu_utilization <= local.t3_baseline_percent || !local.is_burstable
      hours_until_degrade = local.is_burstable && local.net_credit_burn_per_hour > 0 ? "~${local.hours_until_exhaustion} hours" : "N/A"
    }

    risk_assessment = {
      risk_level                   = local.risk_level
      performance_after_exhaustion = local.performance_after_exhaustion
    }
  } : null
}

output "blast_radius" {
  description = "Connected resources"
  value = var.enabled ? {
    compute = [
      "aws_instance.api_server",
      "aws_iam_role.api_server",
      "aws_iam_instance_profile.api_server"
    ]
    networking = [
      "aws_lb.api",
      "aws_lb_target_group.api",
      "aws_lb_listener.http",
      "aws_security_group.api_server",
      "aws_security_group.alb",
      "aws_security_group.database"
    ]
    monitoring = [
      "aws_sns_topic.alerts",
      "aws_cloudwatch_metric_alarm.high_cpu",
      "aws_cloudwatch_metric_alarm.unhealthy_targets"
    ]
  } : null
}

