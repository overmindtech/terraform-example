# =============================================================================
# Variables for Scale Testing Infrastructure
# Scale Testing Infrastructure for Overmind
# =============================================================================

# -----------------------------------------------------------------------------
# Core Scaling Variable
# -----------------------------------------------------------------------------

variable "scale_multiplier" {
  type        = number
  default     = 1
  description = <<-EOT
    Multiplier for resource counts. Controls the total number of resources created:
    - 1   = ~175 resources (baseline)
    - 5   = ~870 resources (small scale)
    - 10  = ~1,740 resources (medium scale)
    - 25  = ~4,350 resources (large scale)
    - 50  = ~8,700 resources (stress test)
    
    Resources are distributed across 4 AWS regions.
  EOT

  validation {
    condition     = contains([1, 5, 10, 25, 50], var.scale_multiplier)
    error_message = "scale_multiplier must be 1, 5, 10, 25, or 50."
  }
}

# -----------------------------------------------------------------------------
# Cloud Provider Configuration
# -----------------------------------------------------------------------------

variable "gcp_project_id" {
  type        = string
  description = "GCP project ID for scale testing resources. Set to empty string to disable GCP."
  default     = "" # Set to your GCP project ID to enable GCP resources
}

variable "enable_gcp" {
  type        = bool
  description = "Enable GCP resource creation. Requires gcp_project_id to be set."
  default     = false
}

variable "aws_account_id" {
  type        = string
  description = "AWS account ID for scale testing (used for cross-account references)"
  default     = ""
}

# -----------------------------------------------------------------------------
# Naming and Tagging
# -----------------------------------------------------------------------------

variable "environment" {
  type        = string
  default     = "scale-test"
  description = "Environment name for resource tagging"
}

variable "project_name" {
  type        = string
  default     = "overmind-scale-test"
  description = "Project name for resource naming and tagging"
}

# -----------------------------------------------------------------------------
# Cost Control Options
# -----------------------------------------------------------------------------

variable "enable_ec2_instances" {
  type        = bool
  default     = true
  description = "Whether to create EC2 instances (stopped). Set false to skip EC2 for cost savings."
}

variable "enable_gce_instances" {
  type        = bool
  default     = true
  description = "Whether to create GCE instances (stopped). Set false to skip GCE for cost savings."
}

variable "enable_lambda_functions" {
  type        = bool
  default     = true
  description = "Whether to create Lambda functions. Set false to skip Lambda for cost savings."
}

variable "enable_cloud_functions" {
  type        = bool
  default     = true
  description = "Whether to create Cloud Functions. Set false to skip for cost savings."
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "vpc_cidr_prefix" {
  type        = string
  default     = "10"
  description = "First octet of VPC CIDR blocks. Each region gets a unique second octet."
}

# -----------------------------------------------------------------------------
# EC2/GCE Configuration
# -----------------------------------------------------------------------------

variable "ec2_instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type (kept small for cost control)"
}

variable "gce_machine_type" {
  type        = string
  default     = "e2-micro"
  description = "GCE machine type (kept small for cost control)"
}

variable "ebs_volume_size" {
  type        = number
  default     = 30
  description = "EBS volume size in GB (minimum 30GB for Amazon Linux 2023)"
}

# -----------------------------------------------------------------------------
# Lambda/Cloud Functions Configuration
# -----------------------------------------------------------------------------

variable "lambda_memory_size" {
  type        = number
  default     = 128
  description = "Lambda memory size in MB (kept minimal for cost control)"
}

variable "lambda_timeout" {
  type        = number
  default     = 3
  description = "Lambda timeout in seconds"
}

# -----------------------------------------------------------------------------
# Test Scenarios
# -----------------------------------------------------------------------------

variable "scenario" {
  type        = string
  default     = "none"
  description = <<-EOT
    Test scenario to apply. Each scenario modifies infrastructure to trigger
    specific risks in Overmind. See SCENARIOS.md for details.
    
    AWS Scenarios:
    - none              : No modifications (baseline)
    - lambda_timeout    : Reduce Lambda timeout drastically
    
    AWS High fan-out (large blast radius):
    - shared_sg_open      : Open SSH on SHARED security group (affects all EC2)
    - vpc_peering_change  : Modify ALL VPC peerings (affects all 4 VPCs)
    - central_sns_change  : Modify central SNS policy (affects all SQS queues)
    
    AWS Combined (maximum blast radius):
    - combined_network  : vpc_peering_change + shared_sg_open combined
    - combined_all      : All AWS high-fanout scenarios combined
    - combined_max      : Maximum AWS blast radius
    
    GCP Scenarios (requires enable_gcp = true):
    - shared_firewall_open   : Open SSH on shared firewall rule (affects all GCE)
    - central_pubsub_change  : Modify central Pub/Sub IAM (affects all subscriptions)
    - gce_downgrade          : Downgrade GCE machine type
    - function_timeout       : Reduce Cloud Function timeout
    - combined_gcp_all       : All GCP high-fanout scenarios combined
  EOT

  validation {
    condition = contains([
      "none",
      # AWS scenarios
      "lambda_timeout",
      "shared_sg_open",
      "vpc_peering_change",
      "central_sns_change",
      "combined_network",
      "combined_all",
      "combined_max",
      # GCP scenarios
      "shared_firewall_open",
      "central_pubsub_change",
      "gce_downgrade",
      "function_timeout",
      "combined_gcp_all"
    ], var.scenario)
    error_message = "Invalid scenario. See variable description for valid options."
  }
}

