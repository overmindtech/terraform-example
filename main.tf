locals {
  include_scenarios = true
}

module "scenarios" {
  count = local.include_scenarios ? 1 : 0

  source = "./modules/scenarios"

  example_env = var.example_env
}
