output "vpc_id" {
  value = aws_vpc.main.id
}

output "zone_id" {
  value = aws_route53_zone.private.zone_id
}

output "service_count" {
  value = var.service_count
}

output "broken_indices" {
  description = "Indices of services with dangling DNS records"
  value       = var.broken_indices
}

output "nlb_dns_names" {
  description = "DNS names of all NLBs (unchanged from setup)"
  value       = { for k, v in aws_lb.svc : k => v.dns_name }
}

output "healthy_dns_records" {
  description = "FQDNs of healthy Route53 alias records"
  value       = { for k, v in aws_route53_record.svc : k => v.fqdn }
}

output "dangling_dns_records" {
  description = "FQDNs of broken Route53 records pointing to non-existent IPs"
  value       = { for k, v in aws_route53_record.svc_dangling : k => v.fqdn }
}

output "dangling_ips" {
  description = "The hardcoded IPs that don't belong to any resource"
  value       = { for k, v in aws_route53_record.svc_dangling : k => one(v.records) }
}
