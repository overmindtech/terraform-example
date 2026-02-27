output "vpc_id" {
  value = aws_vpc.main.id
}

output "zone_id" {
  value = aws_route53_zone.private.zone_id
}

output "service_count" {
  value = var.service_count
}

output "nlb_dns_names" {
  description = "DNS names of all NLBs"
  value       = { for k, v in aws_lb.svc : k => v.dns_name }
}

output "dns_records" {
  description = "FQDNs of all Route53 records"
  value       = { for k, v in aws_route53_record.svc : k => v.fqdn }
}
