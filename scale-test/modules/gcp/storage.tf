# =============================================================================
# GCP Module - Storage Resources
# =============================================================================

# -----------------------------------------------------------------------------
# GCS Buckets
# -----------------------------------------------------------------------------

resource "google_storage_bucket" "scale_test" {
  count = local.regional_count.gcs_buckets

  project                     = var.project_id
  name                        = "${local.name_prefix}-bucket-${count.index + 1}-${var.unique_suffix}"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true

  labels = merge(local.labels, {
    index = tostring(count.index + 1)
  })

  # Cost control: lifecycle to delete old objects
  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "Delete"
    }
  }

  versioning {
    enabled = false
  }
}

# -----------------------------------------------------------------------------
# Secret Manager Secrets
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret" "scale_test" {
  count = local.regional_count.secrets

  project   = var.project_id
  secret_id = "${local.name_prefix}-secret-${count.index + 1}"

  labels = merge(local.labels, {
    index = tostring(count.index + 1)
  })

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

# Secret versions (with dummy data)
resource "google_secret_manager_secret_version" "scale_test" {
  count = local.regional_count.secrets

  secret      = google_secret_manager_secret.scale_test[count.index].id
  secret_data = "scale-test-secret-${count.index + 1}-${var.unique_suffix}"
}

