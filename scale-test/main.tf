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
# Local Variables - Cloud Provider Toggles
# -----------------------------------------------------------------------------

locals {
  # Derived from cloud_provider variable
  enable_aws = var.cloud_provider == "aws" || var.cloud_provider == "both"
  enable_gcp = var.cloud_provider == "gcp" || var.cloud_provider == "both"
}

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

  # Lambda timeout (modified by lambda_timeout or combined_max scenario)
  scenario_lambda_timeout = (
    var.scenario == "lambda_timeout" ? 1 :
    var.scenario == "combined_max" ? 1 :
    var.lambda_timeout
  )

  # GCE machine type (modified by gce_downgrade scenario)
  scenario_gce_machine_type = (
    var.scenario == "gce_downgrade" ? "f1-micro" :
    "e2-micro"
  )

  # Cloud Function timeout (modified by function_timeout or combined_gcp_max scenario)
  scenario_function_timeout = (
    var.scenario == "function_timeout" ? 1 :
    var.scenario == "combined_gcp_max" ? 1 :
    60
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
  count  = local.enable_aws ? 1 : 0
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

  # Central resources for cross-region connectivity
  central_bucket_name   = local.enable_aws ? aws_s3_bucket.central[0].id : ""
  central_sns_topic_arn = local.enable_aws ? aws_sns_topic.central[0].arn : ""
}

module "aws_us_west_2" {
  count  = local.enable_aws ? 1 : 0
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

  # Central resources for cross-region connectivity
  central_bucket_name   = local.enable_aws ? aws_s3_bucket.central[0].id : ""
  central_sns_topic_arn = local.enable_aws ? aws_sns_topic.central[0].arn : ""
}

module "aws_eu_west_1" {
  count  = local.enable_aws ? 1 : 0
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

  # Central resources for cross-region connectivity
  central_bucket_name   = local.enable_aws ? aws_s3_bucket.central[0].id : ""
  central_sns_topic_arn = local.enable_aws ? aws_sns_topic.central[0].arn : ""
}

module "aws_ap_southeast_1" {
  count  = local.enable_aws ? 1 : 0
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

  # Central resources for cross-region connectivity
  central_bucket_name   = local.enable_aws ? aws_s3_bucket.central[0].id : ""
  central_sns_topic_arn = local.enable_aws ? aws_sns_topic.central[0].arn : ""
}

# -----------------------------------------------------------------------------
# GCP Modules - Per Region
# -----------------------------------------------------------------------------
# Set enable_gcp = true and gcp_project_id to enable GCP resources

module "gcp_us_central1" {
  count  = local.enable_gcp && var.gcp_project_id != "" ? 1 : 0
  source = "./modules/gcp"

  providers = {
    google = google.us_central1
  }

  project_id       = var.gcp_project_id
  region           = "us-central1"
  scale_multiplier = var.scale_multiplier
  resource_counts  = local.count
  vpc_cidr         = local.vpc_cidrs["us-central1"]
  unique_suffix    = local.unique_suffix
  common_labels    = local.common_tags

  enable_gce       = var.enable_ec2_instances  # Reuse EC2 toggle for GCE
  enable_functions = var.enable_lambda_functions  # Reuse Lambda toggle for Cloud Functions
  machine_type     = local.scenario_gce_machine_type
  function_timeout = local.scenario_function_timeout

  # Central resources for cross-region connectivity
  central_bucket_name  = local.enable_gcp ? google_storage_bucket.central[0].name : ""
  central_pubsub_topic = local.enable_gcp ? google_pubsub_topic.central[0].id : ""
}

module "gcp_us_west1" {
  count  = local.enable_gcp && var.gcp_project_id != "" ? 1 : 0
  source = "./modules/gcp"

  providers = {
    google = google.us_west1
  }

  project_id       = var.gcp_project_id
  region           = "us-west1"
  scale_multiplier = var.scale_multiplier
  resource_counts  = local.count
  vpc_cidr         = local.vpc_cidrs["us-west1"]
  unique_suffix    = local.unique_suffix
  common_labels    = local.common_tags

  enable_gce       = var.enable_ec2_instances
  enable_functions = var.enable_lambda_functions
  machine_type     = local.scenario_gce_machine_type
  function_timeout = local.scenario_function_timeout

  central_bucket_name  = local.enable_gcp ? google_storage_bucket.central[0].name : ""
  central_pubsub_topic = local.enable_gcp ? google_pubsub_topic.central[0].id : ""
}

module "gcp_europe_west1" {
  count  = local.enable_gcp && var.gcp_project_id != "" ? 1 : 0
  source = "./modules/gcp"

  providers = {
    google = google.europe_west1
  }

  project_id       = var.gcp_project_id
  region           = "europe-west1"
  scale_multiplier = var.scale_multiplier
  resource_counts  = local.count
  vpc_cidr         = local.vpc_cidrs["europe-west1"]
  unique_suffix    = local.unique_suffix
  common_labels    = local.common_tags

  enable_gce       = var.enable_ec2_instances
  enable_functions = var.enable_lambda_functions
  machine_type     = local.scenario_gce_machine_type
  function_timeout = local.scenario_function_timeout

  central_bucket_name  = local.enable_gcp ? google_storage_bucket.central[0].name : ""
  central_pubsub_topic = local.enable_gcp ? google_pubsub_topic.central[0].id : ""
}

module "gcp_asia_southeast1" {
  count  = local.enable_gcp && var.gcp_project_id != "" ? 1 : 0
  source = "./modules/gcp"

  providers = {
    google = google.asia_southeast1
  }

  project_id       = var.gcp_project_id
  region           = "asia-southeast1"
  scale_multiplier = var.scale_multiplier
  resource_counts  = local.count
  vpc_cidr         = local.vpc_cidrs["asia-southeast1"]
  unique_suffix    = local.unique_suffix
  common_labels    = local.common_tags

  enable_gce       = var.enable_ec2_instances
  enable_functions = var.enable_lambda_functions
  machine_type     = local.scenario_gce_machine_type
  function_timeout = local.scenario_function_timeout

  central_bucket_name  = local.enable_gcp ? google_storage_bucket.central[0].name : ""
  central_pubsub_topic = local.enable_gcp ? google_pubsub_topic.central[0].id : ""
}

