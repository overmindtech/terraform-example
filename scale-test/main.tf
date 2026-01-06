# =============================================================================
# Main Configuration for Scale Testing Infrastructure
# Scale Testing Infrastructure for Overmind - ENG-2073 / PRD-825
# =============================================================================
#
# This infrastructure creates 100-10,000 AWS and GCP resources for testing
# Overmind's blast radius and risk analysis capabilities at scale.
#
# Usage:
#   terraform apply -var="scale_multiplier=1"    # 100 resources
#   terraform apply -var="scale_multiplier=10"   # 1,000 resources
#   terraform apply -var="scale_multiplier=100"  # 10,000 resources
#
# =============================================================================

# -----------------------------------------------------------------------------
# Local Variables - Resource Counts and Distribution
# -----------------------------------------------------------------------------

locals {
  # Base resource counts (scale_multiplier=1 yields ~100 total resources)
  base = {
    ssm_parameters   = 25 # SSM Parameters / Secret Manager secrets
    sqs_queues       = 15 # SQS queues / Pub/Sub subscriptions
    sns_topics       = 10 # SNS topics / Pub/Sub topics
    log_groups       = 10 # CloudWatch Log Groups
    iam_roles        = 10 # IAM roles / Service accounts
    security_groups  = 5  # Security groups / Firewall rules
    lambda_functions = 5  # Lambda functions / Cloud Functions
    s3_buckets       = 1  # S3 buckets / GCS buckets (per region)
    ec2_instances    = 2  # EC2 instances / GCE instances
    vpc_resources    = 4  # VPCs (1 per region with subnets, routes, etc.)
  }

  # Scaled resource counts
  count = {
    for k, v in local.base : k => v * var.scale_multiplier
  }

  # Total resource count (approximate)
  total_resource_count = sum([for k, v in local.count : v]) * 2 # ×2 for AWS + GCP

  # Multi-region configuration
  aws_regions = ["us-east-1", "us-west-2", "eu-west-1", "ap-southeast-1"]
  gcp_regions = ["us-central1", "us-west1", "europe-west1", "asia-southeast1"]

  # Per-region resource distribution
  per_region_count = ceil(var.scale_multiplier / 4)

  # Unique suffix for globally unique names
  unique_suffix = random_string.suffix.result

  # Common tags/labels
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Multiplier  = tostring(var.scale_multiplier)
  }

  # VPC CIDR blocks per region (ensures no overlap)
  vpc_cidrs = {
    # AWS regions
    "us-east-1"      = "${var.vpc_cidr_prefix}.10.0.0/16"
    "us-west-2"      = "${var.vpc_cidr_prefix}.20.0.0/16"
    "eu-west-1"      = "${var.vpc_cidr_prefix}.30.0.0/16"
    "ap-southeast-1" = "${var.vpc_cidr_prefix}.40.0.0/16"
    # GCP regions
    "us-central1"     = "${var.vpc_cidr_prefix}.110.0.0/16"
    "us-west1"        = "${var.vpc_cidr_prefix}.120.0.0/16"
    "europe-west1"    = "${var.vpc_cidr_prefix}.130.0.0/16"
    "asia-southeast1" = "${var.vpc_cidr_prefix}.140.0.0/16"
  }

  # -----------------------------------------------------------------------------
  # Scenario-Adjusted Values
  # These locals modify infrastructure based on the selected scenario
  # -----------------------------------------------------------------------------

  # EC2 instance type (modified by ec2_downgrade scenario)
  scenario_instance_type = (
    var.scenario == "ec2_downgrade" ? "t3.nano" :
    var.ec2_instance_type
  )

  # Lambda timeout (modified by lambda_timeout scenario)
  scenario_lambda_timeout = (
    var.scenario == "lambda_timeout" ? 1 :
    var.lambda_timeout
  )
}

# -----------------------------------------------------------------------------
# Random Suffix for Unique Naming
# -----------------------------------------------------------------------------

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# -----------------------------------------------------------------------------
# AWS Modules - Per Region
# -----------------------------------------------------------------------------

module "aws_us_east_1" {
  source = "./modules/aws"

  providers = {
    aws = aws.us_east_1
  }

  region           = "us-east-1"
  scale_multiplier = var.scale_multiplier
  resource_counts  = local.count
  vpc_cidr         = local.vpc_cidrs["us-east-1"]
  unique_suffix    = local.unique_suffix
  common_tags      = local.common_tags

  enable_ec2        = var.enable_ec2_instances
  enable_lambda     = var.enable_lambda_functions
  ec2_instance_type = local.scenario_instance_type  # Scenario-aware
  ebs_volume_size   = var.ebs_volume_size
  lambda_memory     = var.lambda_memory_size
  lambda_timeout    = local.scenario_lambda_timeout  # Scenario-aware
}

module "aws_us_west_2" {
  source = "./modules/aws"

  providers = {
    aws = aws.us_west_2
  }

  region           = "us-west-2"
  scale_multiplier = var.scale_multiplier
  resource_counts  = local.count
  vpc_cidr         = local.vpc_cidrs["us-west-2"]
  unique_suffix    = local.unique_suffix
  common_tags      = local.common_tags

  enable_ec2        = var.enable_ec2_instances
  enable_lambda     = var.enable_lambda_functions
  ec2_instance_type = local.scenario_instance_type  # Scenario-aware
  ebs_volume_size   = var.ebs_volume_size
  lambda_memory     = var.lambda_memory_size
  lambda_timeout    = local.scenario_lambda_timeout  # Scenario-aware
}

module "aws_eu_west_1" {
  source = "./modules/aws"

  providers = {
    aws = aws.eu_west_1
  }

  region           = "eu-west-1"
  scale_multiplier = var.scale_multiplier
  resource_counts  = local.count
  vpc_cidr         = local.vpc_cidrs["eu-west-1"]
  unique_suffix    = local.unique_suffix
  common_tags      = local.common_tags

  enable_ec2        = var.enable_ec2_instances
  enable_lambda     = var.enable_lambda_functions
  ec2_instance_type = local.scenario_instance_type  # Scenario-aware
  ebs_volume_size   = var.ebs_volume_size
  lambda_memory     = var.lambda_memory_size
  lambda_timeout    = local.scenario_lambda_timeout  # Scenario-aware
}

module "aws_ap_southeast_1" {
  source = "./modules/aws"

  providers = {
    aws = aws.ap_southeast_1
  }

  region           = "ap-southeast-1"
  scale_multiplier = var.scale_multiplier
  resource_counts  = local.count
  vpc_cidr         = local.vpc_cidrs["ap-southeast-1"]
  unique_suffix    = local.unique_suffix
  common_tags      = local.common_tags

  enable_ec2        = var.enable_ec2_instances
  enable_lambda     = var.enable_lambda_functions
  ec2_instance_type = local.scenario_instance_type  # Scenario-aware
  ebs_volume_size   = var.ebs_volume_size
  lambda_memory     = var.lambda_memory_size
  lambda_timeout    = local.scenario_lambda_timeout  # Scenario-aware
}

# -----------------------------------------------------------------------------
# GCP Modules - Per Region
# -----------------------------------------------------------------------------
# These module blocks will be uncommented as modules are implemented in Phase 3

# module "gcp_us_central1" {
#   source = "./modules/gcp"
#   
#   providers = {
#     google = google.us_central1
#   }
#   
#   region            = "us-central1"
#   project_id        = var.gcp_project_id
#   scale_multiplier  = var.scale_multiplier
#   resource_counts   = local.count
#   vpc_cidr          = local.vpc_cidrs["us-central1"]
#   unique_suffix     = local.unique_suffix
#   common_labels     = local.common_tags
#   
#   enable_gce        = var.enable_gce_instances
#   enable_functions  = var.enable_cloud_functions
#   gce_machine_type  = var.gce_machine_type
# }

# module "gcp_us_west1" {
#   source = "./modules/gcp"
#   
#   providers = {
#     google = google.us_west1
#   }
#   
#   region            = "us-west1"
#   project_id        = var.gcp_project_id
#   scale_multiplier  = var.scale_multiplier
#   resource_counts   = local.count
#   vpc_cidr          = local.vpc_cidrs["us-west1"]
#   unique_suffix     = local.unique_suffix
#   common_labels     = local.common_tags
#   
#   enable_gce        = var.enable_gce_instances
#   enable_functions  = var.enable_cloud_functions
#   gce_machine_type  = var.gce_machine_type
# }

# module "gcp_europe_west1" {
#   source = "./modules/gcp"
#   
#   providers = {
#     google = google.europe_west1
#   }
#   
#   region            = "europe-west1"
#   project_id        = var.gcp_project_id
#   scale_multiplier  = var.scale_multiplier
#   resource_counts   = local.count
#   vpc_cidr          = local.vpc_cidrs["europe-west1"]
#   unique_suffix     = local.unique_suffix
#   common_labels     = local.common_tags
#   
#   enable_gce        = var.enable_gce_instances
#   enable_functions  = var.enable_cloud_functions
#   gce_machine_type  = var.gce_machine_type
# }

# module "gcp_asia_southeast1" {
#   source = "./modules/gcp"
#   
#   providers = {
#     google = google.asia_southeast1
#   }
#   
#   region            = "asia-southeast1"
#   project_id        = var.gcp_project_id
#   scale_multiplier  = var.scale_multiplier
#   resource_counts   = local.count
#   vpc_cidr          = local.vpc_cidrs["asia-southeast1"]
#   unique_suffix     = local.unique_suffix
#   common_labels     = local.common_tags
#   
#   enable_gce        = var.enable_gce_instances
#   enable_functions  = var.enable_cloud_functions
#   gce_machine_type  = var.gce_machine_type
# }

