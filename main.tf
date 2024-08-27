locals {
  include_scenarios    = false
}

module "scenarios" {
  count = local.include_scenarios ? 1 : 0

  source = "./modules/scenarios"

  example_env = var.example_env
}
