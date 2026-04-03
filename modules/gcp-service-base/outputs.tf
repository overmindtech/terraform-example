output "instance_name" {
  description = "Name of the service instance"
  value       = google_compute_instance.service.name
}

output "instance_id" {
  description = "Server-assigned instance ID"
  value       = google_compute_instance.service.instance_id
}

output "instance_internal_ip" {
  description = "Internal IP address of the service instance"
  value       = google_compute_instance.service.network_interface[0].network_ip
}

output "health_check_name" {
  description = "Name of the TCP health check"
  value       = google_compute_health_check.service.name
}

output "alert_policy_name" {
  description = "Display name of the monitoring alert policy"
  value       = google_monitoring_alert_policy.health.display_name
}
