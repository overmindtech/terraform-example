module "base" {
  source = "../gcp-service-base"

  service_name = "payments-api"
  service_port = 443
  network      = var.network
  subnet       = var.subnet
  project_id   = var.project_id
  region       = var.region
  team         = "payments"
  alert_topic  = var.alert_topic
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
