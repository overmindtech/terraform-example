# =============================================================================
# GCP Module - Network Resources
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Network
# -----------------------------------------------------------------------------

resource "google_compute_network" "main" {
  project                 = var.project_id
  name                    = "${local.name_prefix}-vpc"
  auto_create_subnetworks = false
  description             = "Scale test VPC for ${var.region}"
}

# -----------------------------------------------------------------------------
# Subnetworks (3 per region to mirror AWS)
# -----------------------------------------------------------------------------

resource "google_compute_subnetwork" "public" {
  count = 3

  project       = var.project_id
  name          = "${local.name_prefix}-public-${count.index + 1}"
  network       = google_compute_network.main.id
  region        = var.region
  ip_cidr_range = "${local.subnet_prefix}.${count.index * 10}.0/24"

  description = "Public subnet ${count.index + 1}"
}

resource "google_compute_subnetwork" "private" {
  count = 3

  project       = var.project_id
  name          = "${local.name_prefix}-private-${count.index + 1}"
  network       = google_compute_network.main.id
  region        = var.region
  ip_cidr_range = "${local.subnet_prefix}.${100 + count.index * 10}.0/24"

  description                = "Private subnet ${count.index + 1}"
  private_ip_google_access   = true
}

# -----------------------------------------------------------------------------
# Firewall Rules
# -----------------------------------------------------------------------------

# HIGH FAN-OUT: Shared firewall rule attached to all GCE instances via network tag
resource "google_compute_firewall" "high_fanout" {
  project     = var.project_id
  name        = "${local.name_prefix}-high-fanout-fw"
  network     = google_compute_network.main.id
  description = "HIGH FAN-OUT: Shared firewall rule for all GCE instances"

  # Allow internal traffic
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.vpc_cidr]
  target_tags   = ["scale-test"]
}

# Allow SSH from VPC only (baseline - scenarios will open this)
resource "google_compute_firewall" "ssh_internal" {
  project     = var.project_id
  name        = "${local.name_prefix}-ssh-internal"
  network     = google_compute_network.main.id
  description = "Allow SSH from within VPC"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.vpc_cidr]
  target_tags   = ["scale-test"]
}

# Allow egress (default)
resource "google_compute_firewall" "egress" {
  project     = var.project_id
  name        = "${local.name_prefix}-egress"
  network     = google_compute_network.main.id
  description = "Allow all egress"
  direction   = "EGRESS"

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
}

# Per-instance firewall rules (lower fan-out, for comparison)
resource "google_compute_firewall" "per_instance" {
  count = local.regional_count.firewall_rules

  project     = var.project_id
  name        = "${local.name_prefix}-fw-${count.index + 1}"
  network     = google_compute_network.main.id
  description = "Scale test firewall rule ${count.index + 1}"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = [var.vpc_cidr]
  target_tags   = ["scale-test-${count.index + 1}"]
}

# -----------------------------------------------------------------------------
# Cloud Router (for NAT if needed)
# -----------------------------------------------------------------------------

resource "google_compute_router" "main" {
  project = var.project_id
  name    = "${local.name_prefix}-router"
  network = google_compute_network.main.id
  region  = var.region
}

