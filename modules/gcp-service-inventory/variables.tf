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

variable "alert_topic" {
  description = "Full Pub/Sub topic ID for alert notifications"
  type        = string
}
