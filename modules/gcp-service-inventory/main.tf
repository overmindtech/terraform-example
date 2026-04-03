module "base" {
  source = "../gcp-service-base"

  service_name = "inventory-api"
  network      = var.network
  subnet       = var.subnet
  project_id   = var.project_id
  region       = var.region
  team         = "inventory"
  alert_topic  = var.alert_topic
}

resource "google_compute_firewall" "service_ingress" {
  name        = "inventory-api-ingress"
  network     = var.network
  project     = var.project_id
  description = "Allow inventory-api traffic on service and health-check ports"

  allow {
    protocol = "tcp"
    ports    = ["8080", "9090"]
  }

  source_ranges = var.allowed_source_ranges
  target_tags   = ["inventory-api"]
}

resource "google_compute_firewall" "health_check" {
  name        = "inventory-api-health-check"
  network     = var.network
  project     = var.project_id
  description = "Allow Google Cloud health-check probes to inventory-api"

  allow {
    protocol = "tcp"
    ports    = ["9090"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["inventory-api"]
}

resource "google_pubsub_topic" "stock_events" {
  name    = "inventory-stock-events"
  project = var.project_id

  labels = {
    service = "inventory-api"
    team    = "inventory"
  }
}
