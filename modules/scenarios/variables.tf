
variable "example_env" {
  description = "Indicate which example environment to use"
  default     = "github"
  type        = string
}

# Memory optimization demo variables
variable "enable_memory_optimization_demo" {
  description = "Enable the memory optimization demo scenario"
  type        = bool
  default     = true  # Enable demo infrastructure
}

variable "memory_optimization_container_memory" {
  description = "Memory allocation for containers in the demo (2048 = safe, 1024 = breaks)"
  type        = number
  default     = 2048  # Safe baseline configuration
}

variable "memory_optimization_container_count" {
  description = "Number of containers to run in the memory optimization demo"
  type        = number
  default     = 15
}

variable "days_until_black_friday" {
  description = "Days until Black Friday (demo context)"
  type        = number
  default     = 7
}
