# =============================================================================
# Central GCP Resources
# Creates central Pub/Sub topic and GCS bucket for cross-region fan-out
# =============================================================================

# -----------------------------------------------------------------------------
# Central GCS Bucket
# All regional Cloud Functions reference this bucket
# -----------------------------------------------------------------------------

locals {
  # GCP labels must be lowercase
  gcp_labels = { for k, v in local.common_tags : lower(k) => lower(tostring(v)) }
}

resource "google_storage_bucket" "central" {
  count = local.enable_gcp && var.gcp_project_id != "" ? 1 : 0

  provider                    = google.us_central1
  project                     = var.gcp_project_id
  name                        = "ovm-scale-central-${local.unique_suffix}"
  location                    = "US"
  force_destroy               = true
  uniform_bucket_level_access = true

  labels = merge(local.gcp_labels, {
    purpose = "central-fanout"
  })

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "Delete"
    }
  }
}

# -----------------------------------------------------------------------------
# Central Pub/Sub Topic
# All regional subscriptions connect to this topic
# -----------------------------------------------------------------------------

resource "google_pubsub_topic" "central" {
  count = local.enable_gcp && var.gcp_project_id != "" ? 1 : 0

  provider = google.us_central1
  project  = var.gcp_project_id
  name     = "ovm-scale-central-topic-${local.unique_suffix}"

  labels = merge(local.gcp_labels, {
    purpose = "central-fanout"
  })

  message_retention_duration = "86400s"
}

# -----------------------------------------------------------------------------
# Central Pub/Sub Subscriptions (from each region)
# HIGH FAN-OUT: All regions subscribe to the central topic
# -----------------------------------------------------------------------------

# Note: Regional subscriptions are created in the module via central_pubsub_topic variable

# Dead letter topic for central topic
resource "google_pubsub_topic" "central_dlq" {
  count = local.enable_gcp && var.gcp_project_id != "" ? 1 : 0

  provider = google.us_central1
  project  = var.gcp_project_id
  name     = "ovm-scale-central-dlq-${local.unique_suffix}"

  labels = merge(local.gcp_labels, {
    purpose = "central-dlq"
  })
}

