locals {
  region      = data.aws_region.current.name
  account_id  = data.aws_caller_identity.current.account_id
  name_prefix = replace(var.project_name, "/[^a-zA-Z0-9-]/", "-")
  public_azs  = slice(data.aws_availability_zones.available.names, 0, 2)
  tags = merge(
    {
      Project     = var.project_name
      Environment = "demo"
      ManagedBy   = "terraform"
    },
    var.default_tags
  )
}

