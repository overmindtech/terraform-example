variable "example_env" {
  description = "Indicate which example environment to use"
  default     = "terraform-example"
  type        = string
}

# Java application memory optimization settings
variable "enable_memory_optimization_demo" {
  description = "Enable the Java application memory optimization in production"
  type        = bool
  default     = true
}

variable "memory_optimization_container_memory" {
  description = "Memory allocation per ECS container in MB. Optimized based on monitoring data showing 800MB average usage with 950MB peaks."
  type        = number
  default     = 2048

  validation {
    condition     = var.memory_optimization_container_memory >= 512 && var.memory_optimization_container_memory <= 4096
    error_message = "Container memory must be between 512MB and 4GB."
  }
}

variable "memory_optimization_container_count" {
  description = "Number of ECS service instances for load distribution"
  type        = number
  default     = 3

  validation {
    condition     = var.memory_optimization_container_count >= 1 && var.memory_optimization_container_count <= 50
    error_message = "Container count must be between 1 and 50."
  }
}

variable "days_until_black_friday" {
  description = "Business context: Days remaining until Black Friday peak traffic period"
  type        = number
  default     = 7
}

# Message size limit breach demo settings
variable "enable_message_size_breach_demo" {
  description = "Enable the message size limit breach demo scenario"
  type        = bool
  default     = true
}

variable "message_size_breach_max_size" {
  description = "Maximum message size for SQS queue in bytes. 25KB (25600) is safe, 100KB (102400) will break Lambda batch processing. Based on AWS Lambda async payload limit of 256KB."
  type        = number
  default     = 25600 # 25KB - safe default

  validation {
    condition     = var.message_size_breach_max_size >= 1024 && var.message_size_breach_max_size <= 1048576
    error_message = "Message size must be between 1KB and 1MB for this demo. Reference: https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html"
  }
}

variable "message_size_breach_batch_size" {
  description = "Number of messages to process in each Lambda batch. Combined with max_message_size, this determines total payload size"
  type        = number
  default     = 10

  validation {
    condition     = var.message_size_breach_batch_size >= 1 && var.message_size_breach_batch_size <= 10
    error_message = "Batch size must be between 1 and 10 messages."
  }
}

variable "message_size_breach_lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 180

  validation {
    condition     = var.message_size_breach_lambda_timeout >= 30 && var.message_size_breach_lambda_timeout <= 900
    error_message = "Lambda timeout must be between 30 and 900 seconds."
  }
}

variable "message_size_breach_lambda_memory" {
  description = "Lambda function memory allocation in MB"
  type        = number
  default     = 1024

  validation {
    condition     = var.message_size_breach_lambda_memory >= 128 && var.message_size_breach_lambda_memory <= 10240
    error_message = "Lambda memory must be between 128 and 10240 MB."
  }
}

variable "message_size_breach_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 14

  validation {
    condition     = var.message_size_breach_retention_days >= 1 && var.message_size_breach_retention_days <= 3653
    error_message = "Retention days must be between 1 and 3653 days."
  }
}

# API access module settings
variable "enable_api_access" {
  description = "Enable the customer API access module"
  type        = bool
  default     = true
}
