variable "customer_cidrs" {
  description = "Customer IP allowlist for API access. This changes frequently."
  type = map(object({
    cidr = string
    name = string
  }))
  default = {
    acme_corp = {
      cidr = "203.0.113.10/32"
      name = "Acme Corp"
    }
    globex = {
      cidr = "198.51.100.0/29"
      name = "Globex Industries"
    }
    initech = {
      cidr = "192.0.2.50/32"
      name = "Initech"
    }
    umbrella = {
      cidr = "198.18.100.0/24"
      name = "Umbrella Corp"
    }
    cyberdyne = {
      cidr = "100.64.0.0/29"
      name = "Cyberdyne Systems"
    }
  }
}

variable "internal_cidr" {
  description = "Internal network CIDR for service mesh, monitoring, and health checks. This rarely changes. THE NEEDLE MODIFIES THIS."
  type        = string
  default     = "10.0.0.0/8"
}

variable "domain" {
  description = "Domain name for the API Route 53 zone"
  type        = string
  default     = "api.example.com"
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = "alerts@example.com"
}

variable "vpc_id" {
  description = "VPC ID to use for resources (from baseline module)"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs to use for resources (from baseline module)"
  type        = list(string)
  default     = []
}

variable "ami_id" {
  description = "AMI ID to use for EC2 instance (from baseline module)"
  type        = string
  default     = null
}
