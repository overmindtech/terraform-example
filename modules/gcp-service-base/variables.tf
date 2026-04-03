variable "service_name" {
  description = "Name of the service — used for resource naming and GCE network tags"
  type        = string
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
