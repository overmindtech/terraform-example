# variables.tf
# Shared Security Group Configuration

variable "enabled" {
  description = "Enable or disable this module"
  type        = bool
  default     = true
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "platform"
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

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

