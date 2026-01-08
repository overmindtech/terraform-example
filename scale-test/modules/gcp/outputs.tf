# =============================================================================
# GCP Module - Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# Network Outputs
# -----------------------------------------------------------------------------

output "vpc_id" {
  value       = google_compute_network.main.id
  description = "VPC network ID"
}

output "vpc_name" {
  value       = google_compute_network.main.name
  description = "VPC network name"
}

output "vpc_self_link" {
  value       = google_compute_network.main.self_link
  description = "VPC network self link"
}

output "public_subnet_ids" {
  value       = google_compute_subnetwork.public[*].id
  description = "Public subnetwork IDs"
}

output "private_subnet_ids" {
  value       = google_compute_subnetwork.private[*].id
  description = "Private subnetwork IDs"
}

# -----------------------------------------------------------------------------
# High Fan-Out Outputs (for scenarios)
# -----------------------------------------------------------------------------

output "high_fanout_firewall_name" {
  value       = google_compute_firewall.high_fanout.name
  description = "HIGH FAN-OUT: Shared firewall rule name"
}

output "high_fanout_firewall_id" {
  value       = google_compute_firewall.high_fanout.id
  description = "HIGH FAN-OUT: Shared firewall rule ID"
}

output "high_fanout_sa_email" {
  value       = google_service_account.high_fanout.email
  description = "HIGH FAN-OUT: Shared service account email"
}

output "high_fanout_sa_id" {
  value       = google_service_account.high_fanout.id
  description = "HIGH FAN-OUT: Shared service account ID"
}

# -----------------------------------------------------------------------------
# Compute Outputs
# -----------------------------------------------------------------------------

output "gce_instance_ids" {
  value       = google_compute_instance.scale_test[*].id
  description = "GCE instance IDs"
}

output "gce_instance_names" {
  value       = google_compute_instance.scale_test[*].name
  description = "GCE instance names"
}

output "function_names" {
  value       = google_cloudfunctions2_function.scale_test[*].name
  description = "Cloud Function names"
}

# -----------------------------------------------------------------------------
# Messaging Outputs
# -----------------------------------------------------------------------------

output "pubsub_topic_ids" {
  value       = google_pubsub_topic.scale_test[*].id
  description = "Pub/Sub topic IDs"
}

output "pubsub_subscription_ids" {
  value       = google_pubsub_subscription.scale_test[*].id
  description = "Pub/Sub subscription IDs"
}

# -----------------------------------------------------------------------------
# Storage Outputs
# -----------------------------------------------------------------------------

output "bucket_names" {
  value       = google_storage_bucket.scale_test[*].name
  description = "GCS bucket names"
}

output "secret_ids" {
  value       = google_secret_manager_secret.scale_test[*].id
  description = "Secret Manager secret IDs"
}

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

output "resource_summary" {
  value = {
    region            = var.region
    vpc               = google_compute_network.main.name
    gce_instances     = length(google_compute_instance.scale_test)
    cloud_functions   = length(google_cloudfunctions2_function.scale_test)
    pubsub_topics     = length(google_pubsub_topic.scale_test)
    pubsub_subs       = length(google_pubsub_subscription.scale_test)
    gcs_buckets       = length(google_storage_bucket.scale_test)
    secrets           = length(google_secret_manager_secret.scale_test)
    firewall_rules    = length(google_compute_firewall.per_instance) + 3 # +3 for high_fanout, ssh, egress
  }
  description = "Summary of resources created in this region"
}

