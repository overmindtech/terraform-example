module "base" {
  source = "../gcp-service-base"

  service_name = "inventory-api"
  service_port = 8080
  network      = var.network
  subnet       = var.subnet
  project_id   = var.project_id
  region       = var.region
  team         = "inventory"
  alert_topic  = var.alert_topic
}

resource "google_pubsub_topic" "stock_events" {
  name    = "inventory-stock-events"
  project = var.project_id

  labels = {
    service = "inventory-api"
    team    = "inventory"
  }
}
