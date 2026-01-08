# =============================================================================
# GCP Module - IAM Resources
# =============================================================================

# -----------------------------------------------------------------------------
# HIGH FAN-OUT: Shared Service Account (used by all GCE and Cloud Functions)
# -----------------------------------------------------------------------------

resource "google_service_account" "high_fanout" {
  project      = var.project_id
  account_id   = "${local.name_prefix}-shared-sa"
  display_name = "Scale Test Shared Service Account"
  description  = "HIGH FAN-OUT: Used by all GCE instances and Cloud Functions in ${var.region}"
}

# Grant basic roles to shared service account
resource "google_project_iam_member" "high_fanout_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.high_fanout.email}"
}

resource "google_project_iam_member" "high_fanout_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.high_fanout.email}"
}

# Allow SA to read from central bucket (if configured)
resource "google_storage_bucket_iam_member" "high_fanout_bucket_reader" {
  count = var.central_bucket_name != "" ? 1 : 0

  bucket = var.central_bucket_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.high_fanout.email}"
}

# Allow SA to publish to Pub/Sub topics
resource "google_project_iam_member" "high_fanout_pubsub" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.high_fanout.email}"
}

# -----------------------------------------------------------------------------
# Per-Resource Service Accounts (lower fan-out, for comparison)
# -----------------------------------------------------------------------------

resource "google_service_account" "per_function" {
  count = local.regional_count.functions

  project      = var.project_id
  account_id   = "${local.name_prefix}-fn-sa-${count.index + 1}"
  display_name = "Function SA ${count.index + 1}"
  description  = "Service account for Cloud Function ${count.index + 1}"
}

# -----------------------------------------------------------------------------
# GCE Instance Service Account (for instance profile equivalent)
# -----------------------------------------------------------------------------

resource "google_service_account" "gce" {
  project      = var.project_id
  account_id   = "${local.name_prefix}-gce-sa"
  display_name = "GCE Service Account"
  description  = "Service account for GCE instances in ${var.region}"
}

resource "google_project_iam_member" "gce_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gce.email}"
}

