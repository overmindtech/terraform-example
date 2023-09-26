locals {
  include_loom_example = false
}

# Example of Loom outage configuration
module "loom" {
  count = local.include_loom_example ? 1 : 0

  source = "./modules/loom"
}
