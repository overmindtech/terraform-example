# =============================================================================
# GCP Module - Provider Requirements
# =============================================================================

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

