# variables.tf
# ECS Java application memory allocation configuration
# Infrastructure variables for production memory optimization

variable "enabled" {
  description = "Enable the ECS service and associated infrastructure"
  type        = bool
  default     = true
}

variable "name_prefix" {
  description = "Resource naming prefix for consistent identification"
  type        = string
  default     = "java-app"
}

variable "container_memory" {
  description = "Memory allocation per container in MB. Current monitoring shows 800MB average usage."
  type        = number
  default     = 2048
  
  validation {
    condition = var.container_memory >= 512 && var.container_memory <= 30720
    error_message = "Container memory must be between 512 MB and 30 GB."
  }
}

variable "number_of_containers" {
  description = "ECS service desired count for high availability and load distribution"
  type        = number
  default     = 15
  
  validation {
    condition = var.number_of_containers >= 1 && var.number_of_containers <= 100
    error_message = "Number of containers must be between 1 and 100."
  }
}

variable "use_default_vpc" {
  description = "Use account's default VPC (mutually exclusive with create_standalone_vpc)"
  type        = bool
  default     = true
}

variable "create_standalone_vpc" {
  description = "Create an isolated VPC for this demo (mutually exclusive with use_default_vpc)"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID to use (only when both use_default_vpc and create_standalone_vpc are false)"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs to use (only when both use_default_vpc and create_standalone_vpc are false)"
  type        = list(string)
  default     = []
}

variable "days_until_black_friday" {
  description = "Context for urgency - days until Black Friday traffic spike"
  type        = number
  default     = 7
}

variable "days_since_last_memory_change" {
  description = "Shows staleness - days since last memory configuration change"
  type        = number
  default     = 423
}

# Additional configuration variables
variable "java_heap_size_mb" {
  description = "Java heap size in MB (this is the trap - app is configured with -Xmx1536m)"
  type        = number
  default     = 1536
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the ECS cluster"
  type        = bool
  default     = false  # Disabled for cost optimization
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds (JVM needs time to start)"
  type        = number
  default     = 120
}

variable "deregistration_delay" {
  description = "ALB target deregistration delay in seconds (5 seconds = no rollback time!)"
  type        = number
  default     = 5
}

variable "application_port" {
  description = "Port the Tomcat application listens on"
  type        = number
  default     = 8080
}

variable "cpu_units" {
  description = "CPU units for ECS task (1024 = 1 vCPU)"
  type        = number
  default     = 512  # Reduced from 1024 for cost savings
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}