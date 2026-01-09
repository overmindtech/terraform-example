# =============================================================================
# Outputs for Scale Testing Infrastructure
# Scale Testing Infrastructure for Overmind
# =============================================================================

# -----------------------------------------------------------------------------
# Scale Summary
# -----------------------------------------------------------------------------

output "scale_summary" {
  description = "Summary of the scale test configuration"
  value = {
    multiplier          = var.scale_multiplier
    total_resources     = local.total_resource_count
    resources_per_cloud = local.total_resource_count / 2
    aws_regions         = local.aws_regions
    gcp_regions         = local.gcp_regions
  }
}

# -----------------------------------------------------------------------------
# Resource Counts by Type
# -----------------------------------------------------------------------------

output "resource_counts" {
  description = "Breakdown of resource counts by type"
  value = {
    # AWS Resources
    aws = {
      vpcs              = local.count.vpc_resources
      subnets           = local.count.vpc_resources * 2 # public + private per VPC
      security_groups   = local.count.security_groups
      ec2_instances     = var.enable_ec2_instances ? local.count.ec2_instances : 0
      lambda_functions  = var.enable_lambda_functions ? local.count.lambda_functions : 0
      iam_roles         = local.count.iam_roles
      s3_buckets        = local.count.s3_buckets
      sqs_queues        = local.count.sqs_queues
      sns_topics        = local.count.sns_topics
      ssm_parameters    = local.count.ssm_parameters
      cloudwatch_groups = local.count.log_groups
    }

    # GCP Resources
    gcp = {
      vpcs             = local.count.vpc_resources
      subnets          = local.count.vpc_resources * 2
      firewall_rules   = local.count.security_groups
      gce_instances    = var.enable_gce_instances ? local.count.ec2_instances : 0
      cloud_functions  = var.enable_cloud_functions ? local.count.lambda_functions : 0
      service_accounts = local.count.iam_roles
      gcs_buckets      = local.count.s3_buckets
      pubsub_topics    = local.count.sns_topics
      pubsub_subs      = local.count.sqs_queues
      secret_manager   = local.count.ssm_parameters
    }
  }
}

# -----------------------------------------------------------------------------
# Cost Estimates
# -----------------------------------------------------------------------------

output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown (USD)"
  value = {
    note = "Estimates assume resources are stopped/idle. Actual costs may vary."

    aws = {
      ec2_stopped     = var.enable_ec2_instances ? local.count.ec2_instances * 0.50 : 0
      ebs_storage     = var.enable_ec2_instances ? local.count.ec2_instances * var.ebs_volume_size * 0.08 : 0
      lambda_idle     = 0                              # No cost when not invoked
      s3_empty        = local.count.s3_buckets * 0.023 # Minimal for empty buckets
      sqs_idle        = 0                              # No cost when not used
      sns_idle        = 0                              # No cost when not used
      cloudwatch_logs = local.count.log_groups * 0.50
      ssm_parameters  = 0 # Free tier covers standard params
    }

    gcp = {
      gce_stopped    = var.enable_gce_instances ? local.count.ec2_instances * 0.40 : 0
      disk_storage   = var.enable_gce_instances ? local.count.ec2_instances * var.ebs_volume_size * 0.04 : 0
      functions_idle = 0 # No cost when not invoked
      gcs_empty      = local.count.s3_buckets * 0.020
      pubsub_idle    = 0                                             # No cost when not used
      secret_manager = local.count.ssm_parameters * 0.06 / 10000 * 6 # Per secret version
    }

    total_estimate = format("$%.2f - $%.2f/month",
      # Low estimate
      (var.enable_ec2_instances ? local.count.ec2_instances * 0.50 : 0) +
      (var.enable_gce_instances ? local.count.ec2_instances * 0.40 : 0) +
      local.count.log_groups * 0.30,
      # High estimate  
      (var.enable_ec2_instances ? local.count.ec2_instances * 1.00 : 0) +
      (var.enable_gce_instances ? local.count.ec2_instances * 0.80 : 0) +
      local.count.log_groups * 0.50 +
      local.count.s3_buckets * 0.10
    )
  }
}

# -----------------------------------------------------------------------------
# Region Distribution
# -----------------------------------------------------------------------------

output "region_distribution" {
  description = "How resources are distributed across regions"
  value = {
    resources_per_aws_region = local.per_region_count
    resources_per_gcp_region = local.per_region_count

    aws_regions = {
      for region in local.aws_regions : region => {
        vpc_count    = ceil(local.count.vpc_resources / 4)
        ec2_count    = var.enable_ec2_instances ? ceil(local.count.ec2_instances / 4) : 0
        lambda_count = var.enable_lambda_functions ? ceil(local.count.lambda_functions / 4) : 0
        sqs_count    = ceil(local.count.sqs_queues / 4)
        sns_count    = ceil(local.count.sns_topics / 4)
      }
    }

    gcp_regions = {
      for region in local.gcp_regions : region => {
        vpc_count      = ceil(local.count.vpc_resources / 4)
        gce_count      = var.enable_gce_instances ? ceil(local.count.ec2_instances / 4) : 0
        function_count = var.enable_cloud_functions ? ceil(local.count.lambda_functions / 4) : 0
        pubsub_count   = ceil(local.count.sns_topics / 4)
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Validation Info
# -----------------------------------------------------------------------------

output "validation_info" {
  description = "Information for validating the scale test with Overmind"
  value = {
    overmind_app_url = "https://app.overmind.tech"

    expected_discovery = {
      aws_account = var.aws_account_id != "" ? var.aws_account_id : "Configure aws_account_id variable"
      gcp_project = var.gcp_project_id
    }

    tags_for_filtering = {
      project     = var.project_name
      environment = var.environment
      multiplier  = var.scale_multiplier
    }

    next_steps = [
      "1. Run 'terraform apply' to create resources",
      "2. Verify resources appear in prod Overmind sources",
      "3. Create a change in Overmind and analyze blast radius",
      "4. Run benchmark tests (PRD-826)",
      "5. Clean up with 'terraform destroy'"
    ]
  }
}

# -----------------------------------------------------------------------------
# AWS Regional Summaries
# -----------------------------------------------------------------------------

output "aws_us_east_1_summary" {
  description = "Resource summary for AWS us-east-1"
  value       = local.enable_aws ? module.aws_us_east_1[0].resource_summary : null
}

output "aws_us_west_2_summary" {
  description = "Resource summary for AWS us-west-2"
  value       = local.enable_aws ? module.aws_us_west_2[0].resource_summary : null
}

output "aws_eu_west_1_summary" {
  description = "Resource summary for AWS eu-west-1"
  value       = local.enable_aws ? module.aws_eu_west_1[0].resource_summary : null
}

output "aws_ap_southeast_1_summary" {
  description = "Resource summary for AWS ap-southeast-1"
  value       = local.enable_aws ? module.aws_ap_southeast_1[0].resource_summary : null
}

