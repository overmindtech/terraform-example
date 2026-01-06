# =============================================================================
# AWS Module Variables
# Scale Testing Infrastructure for Overmind
# =============================================================================

variable "region" {
  type        = string
  description = "AWS region for this module instance"
}

variable "scale_multiplier" {
  type        = number
  description = "Scale multiplier (1, 10, or 100)"
}

variable "resource_counts" {
  type        = map(number)
  description = "Map of resource type to count"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "unique_suffix" {
  type        = string
  description = "Unique suffix for globally unique resource names"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
}

variable "enable_ec2" {
  type        = bool
  default     = true
  description = "Whether to create EC2 instances"
}

variable "enable_lambda" {
  type        = bool
  default     = true
  description = "Whether to create Lambda functions"
}

variable "ec2_instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type"
}

variable "ebs_volume_size" {
  type        = number
  default     = 4
  description = "EBS volume size in GB"
}

variable "lambda_memory" {
  type        = number
  default     = 128
  description = "Lambda memory size in MB"
}

variable "lambda_timeout" {
  type        = number
  default     = 3
  description = "Lambda timeout in seconds"
}

variable "central_bucket_name" {
  type        = string
  default     = ""
  description = "Name of central S3 bucket (creates cross-region reference)"
}

variable "central_sns_topic_arn" {
  type        = string
  default     = ""
  description = "ARN of central SNS topic (creates cross-region reference)"
}

