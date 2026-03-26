output "instance_name" {
  description = "Name of the inventory API instance"
  value       = module.base.instance_name
}

output "instance_internal_ip" {
  description = "Internal IP of the inventory API instance"
  value       = module.base.instance_internal_ip
}

output "firewall_rule_name" {
  description = "Name of the inventory ingress firewall rule"
  value       = module.base.firewall_rule_name
}

output "health_check_name" {
  description = "Name of the inventory health check"
  value       = module.base.health_check_name
}

output "stock_events_topic" {
  description = "Pub/Sub topic for inventory stock events"
  value       = google_pubsub_topic.stock_events.name
}
