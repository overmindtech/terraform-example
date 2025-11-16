locals {
  include_scenarios = true
}

module "scenarios" {
  count = local.include_scenarios ? 1 : 0

  source = "./modules/scenarios"

  example_env = var.example_env
}

module "serverless_demo" {
  count = var.enable_demo ? 1 : 0

  source = "./modules/demo"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  project_name                 = var.project_name
  allowed_uploader_cidr_blocks = var.allowed_uploader_cidr_blocks
  slack_webhook_url            = var.slack_webhook_url
  default_tags                 = var.default_tags
  aurora_min_acus              = var.aurora_min_acus
  aurora_max_acus              = var.aurora_max_acus
  budget_monthly_limit         = var.budget_monthly_limit
  bastion_key_name             = var.bastion_key_name
}
