output "api_server_id" {
  description = "EC2 instance ID of the API server"
  value       = aws_instance.api_server.id
}

output "api_server_private_ip" {
  description = "Private IP of the API server"
  value       = aws_instance.api_server.private_ip
}

output "api_public_ip" {
  description = "Public IP (EIP) of the API server"
  value       = aws_eip.api_server.public_ip
}

output "api_endpoint" {
  description = "HTTPS endpoint for the API"
  value       = "https://${var.domain}"
}

output "customer_sg_id" {
  description = "Security group ID for customer access (frequently modified)"
  value       = aws_security_group.customer_access.id
}

output "internal_sg_id" {
  description = "Security group ID for internal services (rarely modified - the needle)"
  value       = aws_security_group.internal_services.id
}

output "health_check_id" {
  description = "Route 53 health check ID"
  value       = aws_route53_health_check.api.id
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = aws_route53_zone.api.zone_id
}

output "route53_nameservers" {
  description = "Nameservers for the Route 53 zone (configure at registrar)"
  value       = aws_route53_zone.api.name_servers
}
