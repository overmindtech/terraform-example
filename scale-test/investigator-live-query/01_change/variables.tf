variable "service_count" {
  type        = number
  default     = 20
  description = <<-EOT
    Number of identical service stacks. Must match the value used in 00_setup/.
      - 20  = default (good for correctness testing)
      - 50  = stress test (find the performance breaking point)
  EOT

  validation {
    condition     = var.service_count >= 1 && var.service_count <= 100
    error_message = "service_count must be between 1 and 100."
  }
}

variable "broken_indices" {
  type        = list(number)
  default     = [0, 3, 7, 11, 14, 18]
  description = <<-EOT
    Indices of services whose Route53 records should be switched from NLB
    alias records to hardcoded A records pointing to non-existent private
    IPs (10.0.99.X). These IPs don't belong to any resource and won't
    appear in the blast radius.

    The investigator should:
      - Flag these as dangling references (is_risk_real: true)
      - Use live query tools to confirm the IPs don't exist
      - Only query the broken services, not all of them

    Default: 6 out of 20 services broken (30% failure rate).
  EOT
}
