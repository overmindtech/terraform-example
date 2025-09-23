
variable "example_env" {
  description = "Indicate which example environment to use"
  default     = "github"
  type        = string
}

# Java application memory optimization settings
variable "enable_memory_optimization_demo" {
  description = "Enable the Java application memory optimization in production"
  type        = bool
  default     = true
}

variable "memory_optimization_container_memory" {
  description = "Memory allocation per ECS container in MB. Based on monitoring analysis showing 800MB average usage."
  type        = number
  default     = 1024
  
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
