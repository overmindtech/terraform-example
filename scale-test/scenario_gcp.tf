# =============================================================================
# GCP Test Scenarios
# Scenarios that modify GCP infrastructure to trigger risks in Overmind
# =============================================================================
#
# Lessons learned from AWS:
# - IAM creation scenarios don't work (new resources have no ID until apply)
# - High fan-out scenarios work best (modify shared resources)
# - Modify existing resources, don't create new ones
#
# =============================================================================

# -----------------------------------------------------------------------------
# Scenario: shared_firewall_open
# Opens SSH (port 22) on the SHARED firewall rule attached to all GCE instances
# HIGH FAN-OUT: Affects all GCE instances in each region
# -----------------------------------------------------------------------------

resource "google_compute_firewall" "scenario_ssh_open_us_central1" {
  count = local.enable_gcp && var.scenario == "shared_firewall_open" ? 1 : 0

  provider    = google.us_central1
  project     = var.gcp_project_id
  name        = "ovm-scale-us-central1-${local.unique_suffix}-scenario-ssh"
  network     = module.gcp_us_central1[0].vpc_name
  description = "SCENARIO: SSH open to internet"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["scale-test"]
}

resource "google_compute_firewall" "scenario_ssh_open_us_west1" {
  count = local.enable_gcp && var.scenario == "shared_firewall_open" ? 1 : 0

  provider    = google.us_west1
  project     = var.gcp_project_id
  name        = "ovm-scale-us-west1-${local.unique_suffix}-scenario-ssh"
  network     = module.gcp_us_west1[0].vpc_name
  description = "SCENARIO: SSH open to internet"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["scale-test"]
}

resource "google_compute_firewall" "scenario_ssh_open_europe_west1" {
  count = local.enable_gcp && var.scenario == "shared_firewall_open" ? 1 : 0

  provider    = google.europe_west1
  project     = var.gcp_project_id
  name        = "ovm-scale-europe-west1-${local.unique_suffix}-scenario-ssh"
  network     = module.gcp_europe_west1[0].vpc_name
  description = "SCENARIO: SSH open to internet"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["scale-test"]
}

resource "google_compute_firewall" "scenario_ssh_open_asia_southeast1" {
  count = local.enable_gcp && var.scenario == "shared_firewall_open" ? 1 : 0

  provider    = google.asia_southeast1
  project     = var.gcp_project_id
  name        = "ovm-scale-asia-southeast1-${local.unique_suffix}-scenario-ssh"
  network     = module.gcp_asia_southeast1[0].vpc_name
  description = "SCENARIO: SSH open to internet"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["scale-test"]
}

# -----------------------------------------------------------------------------
# Scenario: central_pubsub_change
# Modifies the central Pub/Sub topic IAM policy
# HIGH FAN-OUT: Affects all regional subscriptions
# -----------------------------------------------------------------------------

resource "google_pubsub_topic_iam_member" "scenario_central_pubsub" {
  count = local.enable_gcp && var.scenario == "central_pubsub_change" ? 1 : 0

  provider = google.us_central1
  project  = var.gcp_project_id
  topic    = google_pubsub_topic.central[0].name
  role     = "roles/pubsub.viewer"
  member   = "allAuthenticatedUsers"
}

# -----------------------------------------------------------------------------
# Scenario: gce_downgrade
# Downgrades GCE machine type from e2-micro to f1-micro
# LOW FAN-OUT: Tests GCE adapter
# Note: This is handled via local.scenario_gce_machine_type in main.tf
# -----------------------------------------------------------------------------

# (Machine type change is automatic via local.scenario_gce_machine_type)

# -----------------------------------------------------------------------------
# Scenario: function_timeout
# Reduces Cloud Function timeout from 60s to 1s
# LOW FAN-OUT: Tests Cloud Functions adapter
# Note: This is handled via local.scenario_function_timeout in main.tf
# -----------------------------------------------------------------------------

# (Timeout change is automatic via local.scenario_function_timeout)

# -----------------------------------------------------------------------------
# Scenario: combined_gcp_all
# Combines all GCP high-fanout scenarios
# MAXIMUM BLAST RADIUS
# -----------------------------------------------------------------------------

# Firewall open for combined scenario
resource "google_compute_firewall" "combined_ssh_open_us_central1" {
  count = local.enable_gcp && var.scenario == "combined_gcp_all" ? 1 : 0

  provider    = google.us_central1
  project     = var.gcp_project_id
  name        = "ovm-scale-us-central1-${local.unique_suffix}-combined-ssh"
  network     = module.gcp_us_central1[0].vpc_name
  description = "COMBINED: SSH open to internet"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["scale-test"]
}

resource "google_compute_firewall" "combined_ssh_open_us_west1" {
  count = local.enable_gcp && var.scenario == "combined_gcp_all" ? 1 : 0

  provider    = google.us_west1
  project     = var.gcp_project_id
  name        = "ovm-scale-us-west1-${local.unique_suffix}-combined-ssh"
  network     = module.gcp_us_west1[0].vpc_name
  description = "COMBINED: SSH open to internet"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["scale-test"]
}

resource "google_compute_firewall" "combined_ssh_open_europe_west1" {
  count = local.enable_gcp && var.scenario == "combined_gcp_all" ? 1 : 0

  provider    = google.europe_west1
  project     = var.gcp_project_id
  name        = "ovm-scale-europe-west1-${local.unique_suffix}-combined-ssh"
  network     = module.gcp_europe_west1[0].vpc_name
  description = "COMBINED: SSH open to internet"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["scale-test"]
}

resource "google_compute_firewall" "combined_ssh_open_asia_southeast1" {
  count = local.enable_gcp && var.scenario == "combined_gcp_all" ? 1 : 0

  provider    = google.asia_southeast1
  project     = var.gcp_project_id
  name        = "ovm-scale-asia-southeast1-${local.unique_suffix}-combined-ssh"
  network     = module.gcp_asia_southeast1[0].vpc_name
  description = "COMBINED: SSH open to internet"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["scale-test"]
}

# Central Pub/Sub change for combined scenario
resource "google_pubsub_topic_iam_member" "combined_central_pubsub" {
  count = local.enable_gcp && var.scenario == "combined_gcp_all" ? 1 : 0

  provider = google.us_central1
  project  = var.gcp_project_id
  topic    = google_pubsub_topic.central[0].name
  role     = "roles/pubsub.viewer"
  member   = "allAuthenticatedUsers"
}

