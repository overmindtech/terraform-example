module "base" {
  source = "../gcp-service-base"

  service_name = "payments-api"
  network      = var.network
  subnet       = var.subnet
  project_id   = var.project_id
  region       = var.region
  team         = "payments"
  alert_topic  = var.alert_topic
}

resource "google_compute_firewall" "service_ingress" {
  name        = "payments-api-ingress"
  network     = var.network
  project     = var.project_id
  description = "Allow payments-api traffic on service and health-check ports"

  allow {
    protocol = "tcp"
    ports    = ["443", "9090"]
  }

  source_ranges = var.allowed_source_ranges
  target_tags   = ["payments-api"]
}

resource "google_compute_firewall" "health_check" {
  name        = "payments-api-health-check"
  network     = var.network
  project     = var.project_id
  description = "Allow Google Cloud health-check probes to payments-api"

  allow {
    protocol = "tcp"
    ports    = ["9090"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["payments-api"]
}

resource "google_storage_bucket" "payment_receipts" {
  name                        = "${var.project_id}-payment-receipts"
  location                    = var.region
  project                     = var.project_id
  force_destroy               = true
  uniform_bucket_level_access = true

  labels = {
    service = "payments-api"
    team    = "payments"
  }
}
