# =============================================================================
# GCP Module - Messaging Resources (Pub/Sub)
# =============================================================================

# -----------------------------------------------------------------------------
# Pub/Sub Topics
# -----------------------------------------------------------------------------

resource "google_pubsub_topic" "scale_test" {
  count = local.regional_count.pubsub_topics

  project = var.project_id
  name    = "${local.name_prefix}-topic-${count.index + 1}"

  labels = merge(local.labels, {
    index = tostring(count.index + 1)
  })

  message_retention_duration = "86400s" # 1 day
}

# -----------------------------------------------------------------------------
# Pub/Sub Subscriptions
# -----------------------------------------------------------------------------

resource "google_pubsub_subscription" "scale_test" {
  count = local.regional_count.pubsub_subs

  project = var.project_id
  name    = "${local.name_prefix}-sub-${count.index + 1}"
  topic   = google_pubsub_topic.scale_test[count.index % length(google_pubsub_topic.scale_test)].id

  labels = merge(local.labels, {
    index = tostring(count.index + 1)
  })

  # Cost control: short retention
  message_retention_duration = "600s" # 10 minutes
  retain_acked_messages      = false

  ack_deadline_seconds = 20

  expiration_policy {
    ttl = "2592000s" # 30 days
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
}

# Dead letter topic
resource "google_pubsub_topic" "dlq" {
  count = local.regional_count.pubsub_topics

  project = var.project_id
  name    = "${local.name_prefix}-dlq-${count.index + 1}"

  labels = merge(local.labels, {
    index = tostring(count.index + 1)
    type  = "dlq"
  })
}

# -----------------------------------------------------------------------------
# Central Topic Subscription (if central topic provided)
# -----------------------------------------------------------------------------

resource "google_pubsub_subscription" "central" {
  count = var.central_pubsub_topic != "" ? local.regional_count.pubsub_subs : 0

  project = var.project_id
  name    = "${local.name_prefix}-central-sub-${count.index + 1}"
  topic   = var.central_pubsub_topic

  labels = merge(local.labels, {
    index = tostring(count.index + 1)
    type  = "central"
  })

  message_retention_duration = "600s"
  retain_acked_messages      = false
  ack_deadline_seconds       = 20
}

