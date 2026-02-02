# =============================================================================
# Multi-Region Provider Configuration
# Scale Testing Infrastructure for Overmind
# =============================================================================
# Deploys across 4 AWS regions + 4 GCP regions to distribute resources
# and avoid service limits at scale.
# =============================================================================

# -----------------------------------------------------------------------------
# AWS Providers (4 Regions)
# -----------------------------------------------------------------------------

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "overmind-scale-test"
      Environment = "scale-test"
      ManagedBy   = "terraform"
      Repository  = "terraform-example"
      Multiplier  = tostring(var.scale_multiplier)
    }
  }
}

provider "aws" {
  alias  = "us_west_2"
  region = "us-west-2"

  default_tags {
    tags = {
      Project     = "overmind-scale-test"
      Environment = "scale-test"
      ManagedBy   = "terraform"
      Repository  = "terraform-example"
      Multiplier  = tostring(var.scale_multiplier)
    }
  }
}

provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"

  default_tags {
    tags = {
      Project     = "overmind-scale-test"
      Environment = "scale-test"
      ManagedBy   = "terraform"
      Repository  = "terraform-example"
      Multiplier  = tostring(var.scale_multiplier)
    }
  }
}

provider "aws" {
  alias  = "ap_southeast_1"
  region = "ap-southeast-1"

  default_tags {
    tags = {
      Project     = "overmind-scale-test"
      Environment = "scale-test"
      ManagedBy   = "terraform"
      Repository  = "terraform-example"
      Multiplier  = tostring(var.scale_multiplier)
    }
  }
}

# -----------------------------------------------------------------------------
# GCP Providers (4 Regions)
# -----------------------------------------------------------------------------

# GCP Providers are defined but won't be used when cloud_provider=aws
# Terraform requires them to be defined because modules reference them
# Credentials errors can be ignored when GCP modules are disabled (count=0)

provider "google" {
  alias   = "us_central1"
  project = var.cloud_provider == "gcp" || var.cloud_provider == "both" ? var.gcp_project_id : "dummy"
  region  = "us-central1"

  default_labels = {
    project     = "overmind-scale-test"
    environment = "scale-test"
    managed-by  = "terraform"
    repository  = "terraform-example"
    multiplier  = tostring(var.scale_multiplier)
  }
}

provider "google" {
  alias   = "us_west1"
  project = var.cloud_provider == "gcp" || var.cloud_provider == "both" ? var.gcp_project_id : "dummy"
  region  = "us-west1"

  default_labels = {
    project     = "overmind-scale-test"
    environment = "scale-test"
    managed-by  = "terraform"
    repository  = "terraform-example"
    multiplier  = tostring(var.scale_multiplier)
  }
}

provider "google" {
  alias   = "europe_west1"
  project = var.cloud_provider == "gcp" || var.cloud_provider == "both" ? var.gcp_project_id : "dummy"
  region  = "europe-west1"

  default_labels = {
    project     = "overmind-scale-test"
    environment = "scale-test"
    managed-by  = "terraform"
    repository  = "terraform-example"
    multiplier  = tostring(var.scale_multiplier)
  }
}

provider "google" {
  alias   = "asia_southeast1"
  project = var.cloud_provider == "gcp" || var.cloud_provider == "both" ? var.gcp_project_id : "dummy"
  region  = "asia-southeast1"

  default_labels = {
    project     = "overmind-scale-test"
    environment = "scale-test"
    managed-by  = "terraform"
    repository  = "terraform-example"
    multiplier  = tostring(var.scale_multiplier)
  }
}

# -----------------------------------------------------------------------------
# Random Provider (for unique naming)
# -----------------------------------------------------------------------------

provider "random" {}

# -----------------------------------------------------------------------------
# Archive Provider (for Lambda/Cloud Functions packaging)
# -----------------------------------------------------------------------------

provider "archive" {}

