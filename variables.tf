
variable "example_env" {
  description = "Indicate which example environment to use"
  default     = "terraform-example"
  type        = string
}

variable "enable_demo" {
  description = "Toggle to deploy the serverless demo environment"
  type        = bool
  default     = true
}

variable "project_name" {
  description = "Name prefix applied to demo resources"
  type        = string
  default     = "serverless-recipes"
}

variable "allowed_uploader_cidr_blocks" {
  description = "CIDR blocks allowed to invoke the pre-signed upload endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "slack_webhook_url" {
  description = "Webhook used by the Slack notifier Lambda"
  type        = string
  default     = "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
}

variable "default_tags" {
  description = "Additional tags applied to demo resources"
  type        = map(string)
  default     = {}
}

variable "aurora_min_acus" {
  description = "Minimum Aurora Serverless v2 capacity units"
  type        = number
  default     = 0.5
}

variable "aurora_max_acus" {
  description = "Maximum Aurora Serverless v2 capacity units"
  type        = number
  default     = 4
}

variable "budget_monthly_limit" {
  description = "Monthly budget alert threshold in USD"
  type        = number
  default     = 5
}

variable "bastion_key_name" {
  description = "Existing EC2 key pair name for optional bastion access"
  type        = string
  default     = ""
}
