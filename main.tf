locals {
  include_scenarios = true
}

module "baseline" {
  source = "./modules/baseline"

  example_env = var.example_env
}

# module "heritage" {
#   count = local.include_scenarios ? 1 : 0

#   source = "./modules/heritage"

#   example_env = var.example_env

#   # VPC inputs from baseline
#   vpc_id                    = module.baseline.vpc_id
#   public_subnets            = module.baseline.public_subnets
#   private_subnets           = module.baseline.private_subnets
#   default_security_group_id = module.baseline.default_security_group_id
#   public_route_table_ids    = module.baseline.public_route_table_ids
#   ami_id                    = module.baseline.ami_id

#   # Memory optimization demo settings
#   enable_memory_optimization_demo      = var.enable_memory_optimization_demo
#   memory_optimization_container_memory = var.memory_optimization_container_memory
#   memory_optimization_container_count  = var.memory_optimization_container_count
#   days_until_black_friday              = var.days_until_black_friday

#   # Message size breach demo settings
#   enable_message_size_breach_demo    = var.enable_message_size_breach_demo
#   message_size_breach_max_size       = var.message_size_breach_max_size
#   message_size_breach_batch_size     = var.message_size_breach_batch_size
#   message_size_breach_lambda_timeout = var.message_size_breach_lambda_timeout
#   message_size_breach_lambda_memory  = var.message_size_breach_lambda_memory
#   message_size_breach_retention_days = var.message_size_breach_retention_days
# }

# API Server
module "api_server" {
  source = "./modules/api-server"

  enabled       = true
  instance_type = "c5.large"

  vpc_id         = module.baseline.vpc_id
  public_subnets = module.baseline.public_subnets
  ami_id         = module.baseline.ami_id

  name_prefix = "api"
}

# Shared Security Group Demo
# Demonstrates Overmind's ability to discover manual dependencies
module "shared_security_group" {
  source = "./modules/shared-security-group"

  enabled = true

  vpc_id         = module.baseline.vpc_id
  public_subnets = module.baseline.public_subnets
  ami_id         = module.baseline.ami_id
}

# Customer API access configuration
locals {
  api_customer_cidrs = {
    acme_corp = {
      cidr = "203.0.113.16/30"
      name = "Acme Corp"
    }
    globex = {
      cidr = "198.51.105.0/28"
      name = "Globex Industries"
    }
    initech = {
      cidr = "192.0.2.56/30"
      name = "Initech"
    }
    umbrella = {
      cidr = "198.18.106.0/24"
      name = "Umbrella Corp"
    }
    cyberdyne = {
      cidr = "100.64.5.0/28"
      name = "Cyberdyne Systems"
    }
  }

  api_internal_cidr = "10.0.0.0/8"
  api_domain        = "signals-demo-test.demo"
  api_alert_email   = "alerts@example.com"
}

# Loom CDN incident replication for AGM talk
module "agm_talk" {
  source = "./modules/agm-talk"
}

# =============================================================================
# GCP Platform Infrastructure
# Shared VPC and alerting owned by the platform team. Service teams deploy
# into this network via their own wrapper modules below.
# =============================================================================

resource "google_compute_network" "platform" {
  name                    = "platform-services"
  auto_create_subnetworks = false
  project                 = var.gcp_project_id
}

resource "google_compute_subnetwork" "platform" {
  name          = "platform-europe-west2"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.gcp_region
  network       = google_compute_network.platform.id
  project       = var.gcp_project_id
}

resource "google_compute_firewall" "platform_ssh" {
  name        = "platform-allow-ssh-iap"
  network     = google_compute_network.platform.id
  project     = var.gcp_project_id
  description = "Allow SSH via Identity-Aware Proxy for instance management"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["allow-ssh"]
}

resource "google_pubsub_topic" "platform_alerts" {
  name    = "platform-alerts"
  project = var.gcp_project_id

  labels = {
    environment = "production"
    managed-by  = "terraform"
  }
}

# =============================================================================
# Service Deployments (each team owns their wrapper module)
# =============================================================================

module "payments_service" {
  source = "./modules/gcp-service-payments"

  network     = google_compute_network.platform.id
  subnet      = google_compute_subnetwork.platform.id
  project_id  = var.gcp_project_id
  region      = var.gcp_region
  alert_topic = google_pubsub_topic.platform_alerts.id
}

module "inventory_service" {
  source = "./modules/gcp-service-inventory"

  network     = google_compute_network.platform.id
  subnet      = google_compute_subnetwork.platform.id
  project_id  = var.gcp_project_id
  region      = var.gcp_region
  alert_topic = google_pubsub_topic.platform_alerts.id
}

module "api_access" {
  count  = var.enable_api_access ? 1 : 0
  source = "./modules/signals-demo"

  # Reuse shared infrastructure from baseline module
  vpc_id                 = module.baseline.vpc_id
  subnet_ids             = module.baseline.public_subnets
  ami_id                 = module.baseline.ami_id
  public_route_table_ids = module.baseline.public_route_table_ids
  example_env            = var.example_env

  # Customer CIDRs and other configuration
  customer_cidrs = local.api_customer_cidrs
  internal_cidr  = local.api_internal_cidr
  domain         = local.api_domain
  alert_email    = local.api_alert_email
}
