variable "service_count" {
  type        = number
  default     = 20
  description = <<-EOT
    Number of identical service stacks to create. Each stack includes an NLB,
    target group, listener, and Route53 alias record.
      - 20  = default (good for correctness testing)
      - 50  = stress test (find the performance breaking point)
  EOT

  validation {
    condition     = var.service_count >= 1 && var.service_count <= 100
    error_message = "service_count must be between 1 and 100."
  }
}
