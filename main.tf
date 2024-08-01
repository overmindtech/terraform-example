locals {
  include_loom_example = true
  include_scenarios    = true
}

# Example of Loom outage configuration
module "loom" {
  count = local.include_loom_example ? 1 : 0

  source = "./modules/loom"

  example_env = var.example_env
}

module "scenarios" {
  count = local.include_loom_example ? 1 : 0

  source = "./modules/scenarios"

  example_env = var.example_env
}
