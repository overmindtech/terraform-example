locals {
  include_loom_example = true
  include_scenarios    = true
}

# Example of Loom outage configuration
module "loom" {
  count = local.include_loom_example ? 1 : 0

  source = "./modules/loom"
}

module "scenarios" {
  count = local.include_loom_example ? 1 : 0

  source = "./modules/scenarios"
}