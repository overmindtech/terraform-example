variable "service_name" {
  description = "Name of the service — used for resource naming and GCE network tags"
  type        = string
}

variable "service_port" {
  description = "Primary port the service listens on"
  type        = number
}

variable "allowed_source_ranges" {
  description = "CIDR ranges allowed to reach the service"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

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
  description = "GCP region for regional resources"
  type        = string
}

variable "team" {
  description = "Team identifier for labels and alert routing"
  type        = string
}

variable "alert_topic" {
  description = "Full Pub/Sub topic ID (projects/{project}/topics/{name}) for alert notifications"
  type        = string
}
