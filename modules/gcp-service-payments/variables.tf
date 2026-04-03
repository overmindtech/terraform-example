variable "network" {
  description = "VPC network self_link or ID"
  type        = string
}

variable "subnet" {
  description = "Subnetwork self_link or ID"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "allowed_source_ranges" {
  description = "CIDR ranges allowed to reach the service"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "alert_topic" {
  description = "Full Pub/Sub topic ID for alert notifications"
  type        = string
}
