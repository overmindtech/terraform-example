output "instance_name" {
  description = "Name of the payments API instance"
  value       = module.base.instance_name
}

output "instance_internal_ip" {
  description = "Internal IP of the payments API instance"
  value       = module.base.instance_internal_ip
}

output "firewall_rule_name" {
  description = "Name of the payments ingress firewall rule"
  value       = module.base.firewall_rule_name
}

output "health_check_name" {
  description = "Name of the payments health check"
  value       = module.base.health_check_name
}

output "receipts_bucket_name" {
  description = "GCS bucket for payment receipts"
  value       = google_storage_bucket.payment_receipts.name
}
