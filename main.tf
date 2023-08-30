locals {
  include_loom_example = true
}

# Example of Loom outage configuration
module "loom" {
  count = local.include_loom_example ? 1 : 0

  source = "./modules/loom"
}