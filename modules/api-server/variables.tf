# variables.tf
# API Server Configuration

variable "enabled" {
  description = "Enable or disable this module"
  type        = bool
  default     = true
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "api"
}

variable "instance_type" {
  description = "EC2 instance type for the API server"
  type        = string
  default     = "c5.large"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnets" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "ami_id" {
  description = "AMI ID for the instance"
  type        = string
}

variable "typical_cpu_utilization" {
  description = "Expected average CPU utilization percentage"
  type        = number
  default     = 70
}

variable "workload_description" {
  description = "Description of the workload"
  type        = string
  default     = "API server handling encryption, real-time analysis, and concurrent requests"
}

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

