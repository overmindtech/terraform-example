locals {
  include_scenarios = true
}

# Moved blocks to handle module restructuring without recreating resources
# VPC module moved from scenarios to baseline
moved {
  from = module.scenarios[0].module.vpc
  to   = module.baseline.module.vpc
}

# AMI data source moved from scenarios to baseline
moved {
  from = module.scenarios[0].data.aws_ami.amazon_linux
  to   = module.baseline.data.aws_ami.amazon_linux
}

# Memory optimization module moved from scenarios to heritage
moved {
  from = module.scenarios[0].module.memory_optimization
  to   = module.heritage[0].module.memory_optimization
}

# Message size breach module moved from scenarios to heritage
moved {
  from = module.scenarios[0].module.message_size_breach[0]
  to   = module.heritage[0].module.message_size_breach[0]
}

# All other resources in scenarios module moved to heritage module
# CloudFront module
moved {
  from = module.scenarios[0].module.cloudfront
  to   = module.heritage[0].module.cloudfront
}

# S3 module
moved {
  from = module.scenarios[0].module.s3_one
  to   = module.heritage[0].module.s3_one
}

# ECS module
moved {
  from = module.scenarios[0].module.ecs
  to   = module.heritage[0].module.ecs
}

# All other resources (loom.tf, s3_bucket_notification.tf, sns_lambda.tf, asg_change.tf, manual_sg.tf)
# These are individual resources, so we need to move them individually
# S3 bucket notification resources
moved {
  from = module.scenarios[0].aws_s3_bucket.my_bucket
  to   = module.heritage[0].aws_s3_bucket.my_bucket
}

moved {
  from = module.scenarios[0].aws_sqs_queue.my_queue
  to   = module.heritage[0].aws_sqs_queue.my_queue
}

moved {
  from = module.scenarios[0].aws_s3_bucket_notification.bucket_notification
  to   = module.heritage[0].aws_s3_bucket_notification.bucket_notification
}

moved {
  from = module.scenarios[0].aws_sqs_queue_policy.my_queue_policy
  to   = module.heritage[0].aws_sqs_queue_policy.my_queue_policy
}

# SNS/Lambda resources
moved {
  from = module.scenarios[0].data.archive_file.lambda_zip
  to   = module.heritage[0].data.archive_file.lambda_zip
}

moved {
  from = module.scenarios[0].aws_iam_role.lambda_iam_role
  to   = module.heritage[0].aws_iam_role.lambda_iam_role
}

moved {
  from = module.scenarios[0].aws_lambda_function.example
  to   = module.heritage[0].aws_lambda_function.example
}

moved {
  from = module.scenarios[0].aws_sns_topic.example_topic
  to   = module.heritage[0].aws_sns_topic.example_topic
}

# ASG resources
moved {
  from = module.scenarios[0].aws_launch_template.my_launch_template
  to   = module.heritage[0].aws_launch_template.my_launch_template
}

moved {
  from = module.scenarios[0].aws_lb_target_group.my_target_group
  to   = module.heritage[0].aws_lb_target_group.my_target_group
}

moved {
  from = module.scenarios[0].aws_lb_target_group.my_new_target_group
  to   = module.heritage[0].aws_lb_target_group.my_new_target_group
}

moved {
  from = module.scenarios[0].aws_autoscaling_group.my_asg
  to   = module.heritage[0].aws_autoscaling_group.my_asg
}

# Manual SG resources
moved {
  from = module.scenarios[0].aws_security_group.allow_access
  to   = module.heritage[0].aws_security_group.allow_access
}

moved {
  from = module.scenarios[0].aws_subnet.restricted-2a
  to   = module.heritage[0].aws_subnet.restricted-2a
}

moved {
  from = module.scenarios[0].aws_subnet.restricted-2b
  to   = module.heritage[0].aws_subnet.restricted-2b
}

moved {
  from = module.scenarios[0].aws_route_table_association.restricted-2a
  to   = module.heritage[0].aws_route_table_association.restricted-2a
}

moved {
  from = module.scenarios[0].aws_route_table_association.restricted-2b
  to   = module.heritage[0].aws_route_table_association.restricted-2b
}

moved {
  from = module.scenarios[0].aws_network_acl.restricted
  to   = module.heritage[0].aws_network_acl.restricted
}

moved {
  from = module.scenarios[0].aws_network_acl_rule.allow_http
  to   = module.heritage[0].aws_network_acl_rule.allow_http
}

moved {
  from = module.scenarios[0].aws_network_acl_rule.allow_ssh
  to   = module.heritage[0].aws_network_acl_rule.allow_ssh
}

moved {
  from = module.scenarios[0].aws_network_acl_rule.allow_ephemeral
  to   = module.heritage[0].aws_network_acl_rule.allow_ephemeral
}

moved {
  from = module.scenarios[0].aws_network_acl_rule.deny_high_ports
  to   = module.heritage[0].aws_network_acl_rule.deny_high_ports
}

moved {
  from = module.scenarios[0].aws_network_acl_rule.allow_outbound
  to   = module.heritage[0].aws_network_acl_rule.allow_outbound
}

moved {
  from = module.scenarios[0].aws_instance.webserver
  to   = module.heritage[0].aws_instance.webserver
}

moved {
  from = module.scenarios[0].aws_instance.app_server
  to   = module.heritage[0].aws_instance.app_server
}

moved {
  from = module.scenarios[0].aws_security_group.instance_sg
  to   = module.heritage[0].aws_security_group.instance_sg
}

# Loom resources (CloudFront, S3, ECS, RDS, etc.)
# Data sources
moved {
  from = module.scenarios[0].data.aws_canonical_user_id.current
  to   = module.heritage[0].data.aws_canonical_user_id.current
}

moved {
  from = module.scenarios[0].data.aws_cloudfront_log_delivery_canonical_user_id.cloudfront
  to   = module.heritage[0].data.aws_cloudfront_log_delivery_canonical_user_id.cloudfront
}

moved {
  from = module.scenarios[0].data.aws_iam_policy_document.s3_policy
  to   = module.heritage[0].data.aws_iam_policy_document.s3_policy
}

moved {
  from = module.scenarios[0].data.aws_route53_zone.demo
  to   = module.heritage[0].data.aws_route53_zone.demo
}

moved {
  from = module.scenarios[0].data.aws_ssm_parameter.amzn2_latest
  to   = module.heritage[0].data.aws_ssm_parameter.amzn2_latest
}

moved {
  from = module.scenarios[0].random_pet.this
  to   = module.heritage[0].random_pet.this
}

moved {
  from = module.scenarios[0].random_pet.second
  to   = module.heritage[0].random_pet.second
}

moved {
  from = module.scenarios[0].aws_cloudfront_function.example
  to   = module.heritage[0].aws_cloudfront_function.example
}

moved {
  from = module.scenarios[0].aws_s3_bucket.b
  to   = module.heritage[0].aws_s3_bucket.b
}

moved {
  from = module.scenarios[0].aws_s3_bucket_ownership_controls.b
  to   = module.heritage[0].aws_s3_bucket_ownership_controls.b
}

moved {
  from = module.scenarios[0].aws_s3_bucket_acl.b_acl
  to   = module.heritage[0].aws_s3_bucket_acl.b_acl
}

moved {
  from = module.scenarios[0].aws_cloudfront_origin_access_control.b
  to   = module.heritage[0].aws_cloudfront_origin_access_control.b
}

moved {
  from = module.scenarios[0].aws_cloudfront_distribution.s3_distribution
  to   = module.heritage[0].aws_cloudfront_distribution.s3_distribution
}

moved {
  from = module.scenarios[0].aws_cloudfront_response_headers_policy.headers-policy
  to   = module.heritage[0].aws_cloudfront_response_headers_policy.headers-policy
}

moved {
  from = module.scenarios[0].aws_cloudfront_cache_policy.headers_based_policy
  to   = module.heritage[0].aws_cloudfront_cache_policy.headers_based_policy
}

moved {
  from = module.scenarios[0].aws_cloudfront_origin_request_policy.headers_based_policy
  to   = module.heritage[0].aws_cloudfront_origin_request_policy.headers_based_policy
}

moved {
  from = module.scenarios[0].aws_s3_bucket_policy.bucket_policy
  to   = module.heritage[0].aws_s3_bucket_policy.bucket_policy
}

moved {
  from = module.scenarios[0].aws_lb.main
  to   = module.heritage[0].aws_lb.main
}

moved {
  from = module.scenarios[0].aws_lb_listener.http
  to   = module.heritage[0].aws_lb_listener.http
}

moved {
  from = module.scenarios[0].aws_db_subnet_group.default
  to   = module.heritage[0].aws_db_subnet_group.default
}

moved {
  from = module.scenarios[0].aws_rds_cluster.face_database
  to   = module.heritage[0].aws_rds_cluster.face_database
}

moved {
  from = module.scenarios[0].aws_rds_cluster_instance.face_database
  to   = module.heritage[0].aws_rds_cluster_instance.face_database
}

moved {
  from = module.scenarios[0].aws_ecs_task_definition.face
  to   = module.heritage[0].aws_ecs_task_definition.face
}

moved {
  from = module.scenarios[0].aws_ecs_service.face
  to   = module.heritage[0].aws_ecs_service.face
}

moved {
  from = module.scenarios[0].aws_lb_listener_rule.face
  to   = module.heritage[0].aws_lb_listener_rule.face
}

moved {
  from = module.scenarios[0].aws_lb_target_group.face
  to   = module.heritage[0].aws_lb_target_group.face
}

moved {
  from = module.scenarios[0].aws_route53_record.face
  to   = module.heritage[0].aws_route53_record.face
}

moved {
  from = module.scenarios[0].aws_ecs_task_definition.visit_counter
  to   = module.heritage[0].aws_ecs_task_definition.visit_counter
}

moved {
  from = module.scenarios[0].aws_ecs_service.visit_counter
  to   = module.heritage[0].aws_ecs_service.visit_counter
}

moved {
  from = module.scenarios[0].aws_lb_listener_rule.visit_counter
  to   = module.heritage[0].aws_lb_listener_rule.visit_counter
}

moved {
  from = module.scenarios[0].aws_lb_target_group.visit_counter
  to   = module.heritage[0].aws_lb_target_group.visit_counter
}

moved {
  from = module.scenarios[0].aws_route53_record.visit_counter
  to   = module.heritage[0].aws_route53_record.visit_counter
}

moved {
  from = module.scenarios[0].aws_cloudfront_distribution.visit_counter
  to   = module.heritage[0].aws_cloudfront_distribution.visit_counter
}

module "baseline" {
  source = "./modules/baseline"

  example_env = var.example_env
}

module "heritage" {
  count = local.include_scenarios ? 1 : 0

  source = "./modules/heritage"

  example_env = var.example_env

  # VPC inputs from baseline
  vpc_id                    = module.baseline.vpc_id
  public_subnets            = module.baseline.public_subnets
  private_subnets           = module.baseline.private_subnets
  default_security_group_id = module.baseline.default_security_group_id
  public_route_table_ids    = module.baseline.public_route_table_ids
  ami_id                    = module.baseline.ami_id

  # Memory optimization demo settings
  enable_memory_optimization_demo      = var.enable_memory_optimization_demo
  memory_optimization_container_memory = var.memory_optimization_container_memory
  memory_optimization_container_count  = var.memory_optimization_container_count
  days_until_black_friday              = var.days_until_black_friday

  # Message size breach demo settings
  enable_message_size_breach_demo    = var.enable_message_size_breach_demo
  message_size_breach_max_size       = var.message_size_breach_max_size
  message_size_breach_batch_size     = var.message_size_breach_batch_size
  message_size_breach_lambda_timeout = var.message_size_breach_lambda_timeout
  message_size_breach_lambda_memory  = var.message_size_breach_lambda_memory
  message_size_breach_retention_days = var.message_size_breach_retention_days
}

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

  api_internal_cidr = "10.0.0.0/16" # SECURITY HARDENING: Narrowed to VPC CIDR per audit findings
  api_domain        = "signals-demo-test.demo"
  api_alert_email   = "alerts@example.com"
}

module "api_access" {
  count  = var.enable_api_access ? 1 : 0
  source = "./modules/signals-demo"

  # Reuse shared infrastructure from baseline module
  vpc_id     = module.baseline.vpc_id
  subnet_ids = module.baseline.public_subnets
  ami_id     = module.baseline.ami_id

  # Customer CIDRs and other configuration
  customer_cidrs = local.api_customer_cidrs
  internal_cidr  = local.api_internal_cidr
  domain         = local.api_domain
  alert_email    = local.api_alert_email
}
