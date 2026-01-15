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

variable "cpu_credits" {
  description = "CPU credit option for burstable instances (t2, t3, t4g). Use 'unlimited' for sustained CPU-intensive workloads to prevent throttling."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "unlimited"], var.cpu_credits)
    error_message = "cpu_credits must be either 'standard' or 'unlimited'."
  }
}

