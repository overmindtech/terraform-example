# =============================================================================
# GCP Module - Compute Resources
# =============================================================================

# -----------------------------------------------------------------------------
# GCE Instances (created stopped for cost control)
# -----------------------------------------------------------------------------

resource "google_compute_instance" "scale_test" {
  count = var.enable_gce ? local.regional_count.gce_instances : 0

  project      = var.project_id
  name         = "${local.name_prefix}-gce-${count.index + 1}"
  machine_type = var.machine_type
  zone         = data.google_compute_zones.available.names[count.index % length(data.google_compute_zones.available.names)]

  # Start in stopped state for cost control
  desired_status = "TERMINATED"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.main.id
    subnetwork = google_compute_subnetwork.public[count.index % length(google_compute_subnetwork.public)].id
  }

  # HIGH FAN-OUT: All instances use the shared network tag
  tags = ["scale-test"]

  # Use shared service account
  service_account {
    email  = google_service_account.high_fanout.email
    scopes = ["cloud-platform"]
  }

  labels = merge(local.labels, {
    name  = "${local.name_prefix}-gce-${count.index + 1}"
    index = tostring(count.index + 1)
  })

  metadata = {
    scale-index      = count.index + 1
    scale-multiplier = var.scale_multiplier
  }

  # Prevent accidental deletion
  deletion_protection = false

  lifecycle {
    ignore_changes = [desired_status]
  }
}

# -----------------------------------------------------------------------------
# Cloud Functions (Gen2)
# -----------------------------------------------------------------------------

# Dummy function source
data "archive_file" "function_dummy" {
  type        = "zip"
  output_path = "${path.module}/function_dummy.zip"

  source {
    content  = <<-EOF
      exports.handler = async (req, res) => {
        res.status(200).send('Scale test function');
      };
    EOF
    filename = "index.js"
  }
}

# Function source bucket
resource "google_storage_bucket" "function_source" {
  project                     = var.project_id
  name                        = "${local.name_prefix}-fn-source-${var.unique_suffix}"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true

  labels = local.labels
}

# Upload function source
resource "google_storage_bucket_object" "function_source" {
  name   = "function-source-${var.unique_suffix}.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.function_dummy.output_path
}

# Cloud Functions
resource "google_cloudfunctions2_function" "scale_test" {
  count = var.enable_functions ? local.regional_count.functions : 0

  project  = var.project_id
  name     = "${local.name_prefix}-fn-${count.index + 1}"
  location = var.region

  description = "Scale test Cloud Function ${count.index + 1}"

  build_config {
    runtime     = "nodejs20"
    entry_point = "handler"
    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.function_source.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    min_instance_count = 0
    available_memory   = "${var.function_memory}Mi"
    timeout_seconds    = var.function_timeout

    # HIGH FAN-OUT: All functions use the shared service account
    service_account_email = google_service_account.high_fanout.email

    environment_variables = {
      REGION               = var.region
      SCALE_INDEX          = tostring(count.index + 1)
      SCALE_MULTIPLIER     = tostring(var.scale_multiplier)
      CENTRAL_BUCKET       = var.central_bucket_name
      CENTRAL_PUBSUB_TOPIC = var.central_pubsub_topic
    }
  }

  labels = merge(local.labels, {
    index = tostring(count.index + 1)
  })
}

