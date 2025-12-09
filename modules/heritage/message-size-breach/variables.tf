variable "example_env" {
  description = "Environment name for resource naming"
  type        = string
}

variable "max_message_size" {
  description = "Maximum message size for SQS queue in bytes. 25KB (25600) is safe, 100KB (102400) will break Lambda batch processing. Based on AWS Lambda async payload limit of 256KB."
  type        = number
  default     = 25600  # 25KB - safe default
  
  validation {
    condition     = var.max_message_size >= 1024 && var.max_message_size <= 1048576
    error_message = "Message size must be between 1KB and 1MB for this demo. Use 25600 (25KB) for safe operation or 102400 (100KB) to demonstrate the breach scenario. Reference: https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html"
  }
}

variable "batch_size" {
  description = "Number of messages to process in each Lambda batch. Combined with max_message_size, this determines total payload size"
  type        = number
  default     = 10
  
  validation {
    condition     = var.batch_size >= 1 && var.batch_size <= 10
    error_message = "Batch size must be between 1 and 10 messages."
  }
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 180
  
  validation {
    condition     = var.lambda_timeout >= 30 && var.lambda_timeout <= 900
    error_message = "Lambda timeout must be between 30 and 900 seconds."
  }
}

variable "lambda_memory" {
  description = "Lambda function memory allocation in MB"
  type        = number
  default     = 1024
  
  validation {
    condition     = var.lambda_memory >= 128 && var.lambda_memory <= 10240
    error_message = "Lambda memory must be between 128 and 10240 MB."
  }
}

variable "retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 14
  
  validation {
    condition     = var.retention_days >= 1 && var.retention_days <= 3653
    error_message = "Retention days must be between 1 and 3653 days."
  }
}
