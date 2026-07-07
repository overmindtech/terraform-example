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

# Fraud-detection VPC outputs (the "needle in the haystack") - regulated
# environment owned by the Risk team, reachable only via live peering/NLB
# traversal, not via any Terraform reference to internal_cidr.
output "fraud_detection_vpc_id" {
  description = "ID of the peered, regulated fraud-detection VPC (owned by the Risk team)"
  value       = aws_vpc.fraud_detection.id
}

output "vpc_peering_connection_id" {
  description = "VPC peering connection ID between the core VPC and the fraud-detection VPC"
  value       = aws_vpc_peering_connection.fraud_detection_to_core.id
}

output "fraud_ingest_nlb_arn" {
  description = "ARN of the internal NLB in the fraud-detection VPC that ingests the regulated transaction feed"
  value       = aws_lb.fraud_ingest.arn
}

output "fraud_ingest_nlb_dns_name" {
  description = "DNS name of the internal NLB in the fraud-detection VPC"
  value       = aws_lb.fraud_ingest.dns_name
}

output "txn_feed_target_group_arn" {
  description = "Target group ARN used to pull the regulated transaction feed from the core API into the fraud-detection VPC"
  value       = aws_lb_target_group.txn_feed.arn
}

output "fraud_processor_instance_id" {
  description = "EC2 instance ID of the fraud-detection consumer that reads the regulated transaction feed"
  value       = aws_instance.fraud_processor.id
}
