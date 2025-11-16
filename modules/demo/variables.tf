variable "project_name" {
  description = "Friendly name for tagging and resource prefixes"
  type        = string
}

variable "allowed_uploader_cidr_blocks" {
  description = "CIDR blocks allowed to hit the pre-signed upload endpoint"
  type        = list(string)
}

variable "slack_webhook_url" {
  description = "Webhook for Slack notifications"
  type        = string
}

variable "default_tags" {
  description = "Additional tags applied to every resource"
  type        = map(string)
  default     = {}
}

variable "aurora_min_acus" {
  description = "Minimum Aurora Serverless v2 capacity units"
  type        = number
}

variable "aurora_max_acus" {
  description = "Maximum Aurora Serverless v2 capacity units"
  type        = number
}

variable "budget_monthly_limit" {
  description = "Monthly AWS Budget alarm threshold"
  type        = number
}

variable "bastion_key_name" {
  description = "Optional EC2 key name used on the maintenance bastion"
  type        = string
}

