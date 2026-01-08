# =============================================================================
# GCP Module - Main Configuration
# =============================================================================

locals {
  # Naming convention
  name_prefix = "ovm-scale-${var.region}-${var.unique_suffix}"

  # Regional resource counts (distribute across regions)
  regional_count = {
    gce_instances    = ceil(var.resource_counts.ec2_instances / 4)
    functions        = ceil(var.resource_counts.lambda_functions / 4)
    pubsub_topics    = ceil(var.resource_counts.sns_topics / 4)
    pubsub_subs      = ceil(var.resource_counts.sqs_queues / 4)
    gcs_buckets      = ceil(var.resource_counts.s3_buckets / 4)
    secrets          = ceil(var.resource_counts.ssm_parameters / 4)
    firewall_rules   = ceil(var.resource_counts.security_groups / 4)
  }

  # Common labels with region
  labels = merge(var.common_labels, {
    region = var.region
  })

  # Network CIDR parsing
  vpc_cidr_parts = split(".", var.vpc_cidr)
  subnet_prefix  = "${local.vpc_cidr_parts[0]}.${local.vpc_cidr_parts[1]}"
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
}

data "google_compute_image" "debian" {
  project = "debian-cloud"
  family  = "debian-12"
}

