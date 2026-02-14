locals {
  include_scenarios = true
}

module "baseline" {
  source = "./modules/baseline"

  example_env = var.example_env
}

# module "heritage" {
#   count = local.include_scenarios ? 1 : 0

#   source = "./modules/heritage"

#   example_env = var.example_env

#   # VPC inputs from baseline
#   vpc_id                    = module.baseline.vpc_id
#   public_subnets            = module.baseline.public_subnets
#   private_subnets           = module.baseline.private_subnets
#   default_security_group_id = module.baseline.default_security_group_id
#   public_route_table_ids    = module.baseline.public_route_table_ids
#   ami_id                    = module.baseline.ami_id

#   # Memory optimization demo settings
#   enable_memory_optimization_demo      = var.enable_memory_optimization_demo
#   memory_optimization_container_memory = var.memory_optimization_container_memory
#   memory_optimization_container_count  = var.memory_optimization_container_count
#   days_until_black_friday              = var.days_until_black_friday

#   # Message size breach demo settings
#   enable_message_size_breach_demo    = var.enable_message_size_breach_demo
#   message_size_breach_max_size       = var.message_size_breach_max_size
#   message_size_breach_batch_size     = var.message_size_breach_batch_size
#   message_size_breach_lambda_timeout = var.message_size_breach_lambda_timeout
#   message_size_breach_lambda_memory  = var.message_size_breach_lambda_memory
#   message_size_breach_retention_days = var.message_size_breach_retention_days
# }

# API Server
module "api_server" {
  source = "./modules/api-server"

  enabled       = true
  instance_type = "c5.large"

  vpc_id         = module.baseline.vpc_id
  public_subnets = module.baseline.public_subnets
  ami_id         = module.baseline.ami_id

  name_prefix = "api"
}

# Shared Security Group Demo
# Demonstrates Overmind's ability to discover manual dependencies
module "shared_security_group" {
  source = "./modules/shared-security-group"

  enabled = true

  vpc_id         = module.baseline.vpc_id
  public_subnets = module.baseline.public_subnets
  ami_id         = module.baseline.ami_id
}

# Customer API access configuration
locals {
  api_customer_cidrs = {
    newco_54 = {
      cidr = "203.0.113.154/32"
      name = "NewCo 54"
    }

    newco_53 = {
      cidr = "203.0.113.153/32"
      name = "NewCo 53"
    }

    newco_52 = {
      cidr = "203.0.113.152/32"
      name = "NewCo 52"
    }

    newco_51 = {
      cidr = "203.0.113.151/32"
      name = "NewCo 51"
    }

    newco_50 = {
      cidr = "203.0.113.150/32"
      name = "NewCo 50"
    }

    newco_49 = {
      cidr = "203.0.113.149/32"
      name = "NewCo 49"
    }

    newco_48 = {
      cidr = "203.0.113.148/32"
      name = "NewCo 48"
    }

    newco_47 = {
      cidr = "203.0.113.147/32"
      name = "NewCo 47"
    }

    newco_46 = {
      cidr = "203.0.113.146/32"
      name = "NewCo 46"
    }

    newco_45 = {
      cidr = "203.0.113.145/32"
      name = "NewCo 45"
    }

    newco_44 = {
      cidr = "203.0.113.144/32"
      name = "NewCo 44"
    }

    newco_43 = {
      cidr = "203.0.113.143/32"
      name = "NewCo 43"
    }

    newco_42 = {
      cidr = "203.0.113.142/32"
      name = "NewCo 42"
    }

    newco_41 = {
      cidr = "203.0.113.141/32"
      name = "NewCo 41"
    }

    newco_40 = {
      cidr = "203.0.113.140/32"
      name = "NewCo 40"
    }

    newco_39 = {
      cidr = "203.0.113.139/32"
      name = "NewCo 39"
    }

    newco_38 = {
      cidr = "203.0.113.138/32"
      name = "NewCo 38"
    }

    newco_37 = {
      cidr = "203.0.113.137/32"
      name = "NewCo 37"
    }

    newco_36 = {
      cidr = "203.0.113.136/32"
      name = "NewCo 36"
    }

    newco_35 = {
      cidr = "203.0.113.135/32"
      name = "NewCo 35"
    }

    newco_34 = {
      cidr = "203.0.113.134/32"
      name = "NewCo 34"
    }

    newco_33 = {
      cidr = "203.0.113.133/32"
      name = "NewCo 33"
    }

    newco_32 = {
      cidr = "203.0.113.132/32"
      name = "NewCo 32"
    }

    newco_31 = {
      cidr = "203.0.113.131/32"
      name = "NewCo 31"
    }

    newco_30 = {
      cidr = "203.0.113.130/32"
      name = "NewCo 30"
    }

    newco_29 = {
      cidr = "203.0.113.129/32"
      name = "NewCo 29"
    }

    newco_28 = {
      cidr = "203.0.113.128/32"
      name = "NewCo 28"
    }

    newco_27 = {
      cidr = "203.0.113.127/32"
      name = "NewCo 27"
    }

    newco_26 = {
      cidr = "203.0.113.126/32"
      name = "NewCo 26"
    }

    newco_25 = {
      cidr = "203.0.113.125/32"
      name = "NewCo 25"
    }

    newco_24 = {
      cidr = "203.0.113.124/32"
      name = "NewCo 24"
    }

    newco_23 = {
      cidr = "203.0.113.123/32"
      name = "NewCo 23"
    }

    newco_22 = {
      cidr = "203.0.113.122/32"
      name = "NewCo 22"
    }

    newco_21 = {
      cidr = "203.0.113.121/32"
      name = "NewCo 21"
    }

    newco_20 = {
      cidr = "203.0.113.120/32"
      name = "NewCo 20"
    }

    newco_19 = {
      cidr = "203.0.113.119/32"
      name = "NewCo 19"
    }

    newco_18 = {
      cidr = "203.0.113.118/32"
      name = "NewCo 18"
    }

    newco_17 = {
      cidr = "203.0.113.117/32"
      name = "NewCo 17"
    }

    newco_16 = {
      cidr = "203.0.113.116/32"
      name = "NewCo 16"
    }

    newco_15 = {
      cidr = "203.0.113.115/32"
      name = "NewCo 15"
    }

    newco_14 = {
      cidr = "203.0.113.114/32"
      name = "NewCo 14"
    }

    newco_13 = {
      cidr = "203.0.113.113/32"
      name = "NewCo 13"
    }

    newco_12 = {
      cidr = "203.0.113.112/32"
      name = "NewCo 12"
    }

    newco_11 = {
      cidr = "203.0.113.111/32"
      name = "NewCo 11"
    }

    newco_10 = {
      cidr = "203.0.113.110/32"
      name = "NewCo 10"
    }

    newco_9 = {
      cidr = "203.0.113.109/32"
      name = "NewCo 9"
    }

    newco_8 = {
      cidr = "203.0.113.108/32"
      name = "NewCo 8"
    }

    newco_7 = {
      cidr = "203.0.113.107/32"
      name = "NewCo 7"
    }

    newco_6 = {
      cidr = "203.0.113.106/32"
      name = "NewCo 6"
    }

    newco_5 = {
      cidr = "203.0.113.105/32"
      name = "NewCo 5"
    }

    newco_4 = {
      cidr = "203.0.113.104/32"
      name = "NewCo 4"
    }

    newco_3 = {
      cidr = "203.0.113.103/32"
      name = "NewCo 3"
    }

    newco_2 = {
      cidr = "203.0.113.102/32"
      name = "NewCo 2"
    }

    newco_1 = {
      cidr = "203.0.113.101/32"
      name = "NewCo 1"
    }

    acme_corp = {
      cidr = "203.0.113.16/30"
      name = "Acme Corp"
    }
    globex = {
      cidr = "198.51.105.0/28"
      name = "Globex Industries"
    }
    initech = {
      cidr = "192.0.2.56/30"
      name = "Initech"
    }
    umbrella = {
      cidr = "198.18.106.0/24"
      name = "Umbrella Corp"
    }
    cyberdyne = {
      cidr = "100.64.5.0/28"
      name = "Cyberdyne Systems"
    }
  }

  api_internal_cidr = "10.0.0.0/8"
  api_domain        = "signals-demo-test.demo"
  api_alert_email   = "alerts@example.com"
}

module "api_access" {
  count  = var.enable_api_access ? 1 : 0
  source = "./modules/signals-demo"

  # Reuse shared infrastructure from baseline module
  vpc_id                 = module.baseline.vpc_id
  subnet_ids             = module.baseline.public_subnets
  ami_id                 = module.baseline.ami_id
  public_route_table_ids = module.baseline.public_route_table_ids
  example_env            = var.example_env

  # Customer CIDRs and other configuration
  customer_cidrs = local.api_customer_cidrs
  internal_cidr  = local.api_internal_cidr
  domain         = local.api_domain
  alert_email    = local.api_alert_email
}
