# main.tf
# API Server Infrastructure

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

resource "random_id" "suffix" {
  count       = var.enabled ? 1 : 0
  byte_length = 4
}

locals {
  random_suffix = var.enabled ? random_id.suffix[0].hex : ""
  name_prefix   = "${var.name_prefix}-${local.random_suffix}"

  # Instance type classification
  is_burstable         = can(regex("^t[0-9]", var.instance_type))
  is_compute_optimized = can(regex("^c[0-9]", var.instance_type))

  # T3 baseline calculations (for outputs)
  t3_baseline_percent          = 30
  t3_credits_per_hour_at_100   = 120
  net_credit_burn_per_hour     = local.is_burstable ? max(0, (var.typical_cpu_utilization - local.t3_baseline_percent) * local.t3_credits_per_hour_at_100 / 100) : 0
  initial_credits              = 576
  hours_until_exhaustion       = local.net_credit_burn_per_hour > 0 ? floor(local.initial_credits / local.net_credit_burn_per_hour) : 999
  risk_level                   = local.is_burstable && var.typical_cpu_utilization > local.t3_baseline_percent ? "HIGH" : "LOW"
  performance_after_exhaustion = local.is_burstable ? "${local.t3_baseline_percent}% of normal" : "100% (no degradation)"

  common_tags = merge(var.additional_tags, {
    Environment = "production"
    Project     = "api-platform"
    Workload    = "cpu-intensive"
    CostCenter  = "engineering"
    ManagedBy   = "terraform"
  })
}

data "aws_region" "current" {}

