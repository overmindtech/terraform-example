# =============================================================================
# GCP Module - Input Variables
# =============================================================================

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region for resources"
}

variable "scale_multiplier" {
  type        = number
  description = "Multiplier for resource counts"
}

variable "resource_counts" {
  type        = map(number)
  description = "Map of resource type to count"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block for this region"
}

variable "unique_suffix" {
  type        = string
  description = "Unique suffix for globally unique names"
}

variable "common_labels" {
  type        = map(string)
  description = "Common labels to apply to all resources"
  default     = {}
}

# -----------------------------------------------------------------------------
# Feature Toggles
# -----------------------------------------------------------------------------

variable "enable_gce" {
  type        = bool
  default     = true
  description = "Enable GCE instance creation"
}

variable "enable_functions" {
  type        = bool
  default     = true
  description = "Enable Cloud Functions creation"
}

# -----------------------------------------------------------------------------
# Resource Configuration
# -----------------------------------------------------------------------------

variable "machine_type" {
  type        = string
  default     = "e2-micro"
  description = "GCE machine type"
}

variable "function_memory" {
  type        = number
  default     = 128
  description = "Cloud Function memory in MB"
}

variable "function_timeout" {
  type        = number
  default     = 60
  description = "Cloud Function timeout in seconds"
}

# -----------------------------------------------------------------------------
# Central Resources (for cross-region fan-out)
# -----------------------------------------------------------------------------

variable "central_bucket_name" {
  type        = string
  default     = ""
  description = "Central GCS bucket name for cross-region references"
}

variable "central_pubsub_topic" {
  type        = string
  default     = ""
  description = "Central Pub/Sub topic name for cross-region subscriptions"
}

variable "enable_central_subscriptions" {
  type        = bool
  default     = false
  description = "Enable subscriptions to central Pub/Sub topic (use boolean to avoid count dependency issues)"
}

