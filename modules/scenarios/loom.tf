locals {
  domain_name = "${var.example_env}.modules.tf" # trimsuffix(data.aws_route53_zone.this.name, ".")
  subdomain   = "cdn"
}

#######################
# Loom Outage Example #
#######################
#
# The purpose of this example is to show how complex cloudfront can be even in a
# simple scenario. It consists of:
#
# - Multiple cloudfront distributions
# - Multiple S3 buckets
# - Multiple headers policies, some of which are used by many distributions
# - A load balancer that serves two ECS services
#
# A good demo here is changing the headers in one of the headers policies and
# showing people the blast radius and risks. You can see the full blog here:
# https://overmind.tech/blog/looms-nightmare-aws-outage

module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 3.0"

  #   aliases = ["${local.subdomain}.${local.domain_name}"]

  comment             = "My awesome CloudFront"
  enabled             = true
  http_version        = "http2and3"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = false

  # When you enable additional metrics for a distribution, CloudFront sends up to 8 metrics to CloudWatch in the US East (N. Virginia) Region.
  # This rate is charged only once per month, per metric (up to 8 metrics per distribution).
  create_monitoring_subscription = true

  create_origin_access_identity = true
  origin_access_identities = {
    s3_bucket_one = "My awesome CloudFront can access"
  }

  create_origin_access_control = true
  origin_access_control = {
    (var.example_env) = {
      description      = "CloudFront access to S3"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  origin = {
    # views = {
    #   domain_name = aws_route53_record.visit_counter.name
    # }
    appsync = {
      domain_name = "appsync.${local.domain_name}"
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "match-viewer"
        origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      }

      custom_header = [
        {
          name  = "X-Forwarded-Scheme"
          value = "https"
        },
        {
          name  = "X-Frame-Options"
          value = "SAMEORIGIN"
        }
      ]

      origin_shield = {
        enabled              = true
        origin_shield_region = "us-east-1"
      }
    }

    s3_one = { # with origin access identity (legacy)
      domain_name = module.s3_one.s3_bucket_bucket_regional_domain_name
      s3_origin_config = {
        origin_access_identity = "s3_bucket_one" # key in `origin_access_identities`
        # cloudfront_access_identity_path = "origin-access-identity/cloudfront/E5IGQAA1QO48Z" # external OAI resource
      }
    }

    s3_oac = { # with origin access control settings (recommended)
      domain_name           = module.s3_one.s3_bucket_bucket_regional_domain_name
      origin_access_control = var.example_env # key in `origin_access_control`
      #      origin_access_control_id = "E345SXM82MIOSU" # external OAС resource
    }
  }

  origin_group = {
    group_one = {
      failover_status_codes      = [403, 404, 500, 502]
      primary_member_origin_id   = "appsync"
      secondary_member_origin_id = "s3_one"
    }
  }

  default_cache_behavior = {
    target_origin_id       = "appsync"
    viewer_protocol_policy = "allow-all"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    query_string           = true

    # This is id for SecurityHeadersPolicy copied from https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-response-headers-policies.html
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"
  }

  ordered_cache_behavior = [
    {
      path_pattern           = "/static/*"
      target_origin_id       = "s3_one"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods            = ["GET", "HEAD"]
      cached_methods             = ["GET", "HEAD"]
      compress                   = true
      query_string               = true
      response_headers_policy_id = aws_cloudfront_response_headers_policy.headers-policy.id

      function_association = {
        # Valid keys: viewer-request, viewer-response
        viewer-request = {
          function_arn = aws_cloudfront_function.example.arn
        }

        viewer-response = {
          function_arn = aws_cloudfront_function.example.arn
        }
      }
    }
  ]

  custom_error_response = [{
    error_code         = 404
    response_code      = 404
    response_page_path = "/errors/404.html"
    }, {
    error_code         = 403
    response_code      = 403
    response_page_path = "/errors/403.html"
  }]

  geo_restriction = {
    restriction_type = "whitelist"
    locations        = ["NO", "UA", "US", "GB"]
  }

}

#############
# S3 buckets
#############

data "aws_canonical_user_id" "current" {}
data "aws_cloudfront_log_delivery_canonical_user_id" "cloudfront" {}

module "s3_one" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket_prefix = "s3-one-${random_pet.this.id}"
  force_destroy = true
}

#############################################
# Using packaged function from Lambda module
#############################################

data "aws_iam_policy_document" "s3_policy" {
  # Origin Access Identities
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.s3_one.s3_bucket_arn}/static/*"]

    principals {
      type        = "AWS"
      identifiers = module.cloudfront.cloudfront_origin_access_identity_iam_arns
    }
  }

  # Origin Access Controls
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.s3_one.s3_bucket_arn}/static/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [module.cloudfront.cloudfront_distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = module.s3_one.s3_bucket_id
  policy = data.aws_iam_policy_document.s3_policy.json
}


########
# Extra
########

resource "random_pet" "this" {
  length = 2
}

resource "random_pet" "second" {
  length = 2
}

resource "aws_cloudfront_function" "example" {
  name    = "${var.example_env}-${random_pet.this.id}"
  runtime = "cloudfront-js-1.0"
  code    = file("example-function.js")
}

# Second resource

resource "aws_s3_bucket" "b" {
  bucket_prefix = "second-example-${random_pet.second.id}"

  tags = {
    Name = "Second example bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "b" {
  bucket = aws_s3_bucket.b.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "b_acl" {
  bucket     = aws_s3_bucket.b.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.b]
}

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_origin_access_control" "b" {
  name                              = "example-${var.example_env}"
  description                       = "Example Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.b.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.b.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

  #   aliases = ["mysite.example.com", "yoursite.example.com"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern               = "/content/immutable/*"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    target_origin_id           = local.s3_origin_id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.headers-policy.id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_response_headers_policy" "headers-policy" {
  name    = "baseline-${var.example_env}"
  comment = "This controls which headers are cached for baseline applications. This includes headers that are safe to cache"

  cors_config {
    access_control_allow_credentials = false

    access_control_allow_headers {
      items = [
        "Accept",
        "Accept-Encoding",
        "Content-Encoding",
        "Content-Length",
        "Content-Type",
        "Authorization",
        "X-Requested-With",
      ]
    }

    access_control_allow_methods {
      items = ["GET", "POST", "PUT", "DELETE"]
    }

    access_control_allow_origins {
      items = ["storage.overmind-demo.com", "*.${local.domain_name}"]
    }

    access_control_max_age_sec = 3600
    origin_override            = true
  }

  custom_headers_config {
    items {
      header   = "X-Custom-Header"
      value    = "overmind-demo-${var.example_env}"
      override = true
    }

    items {
      header   = "X-Frame-Options"
      value    = "DENY"
      override = false
    }

    items {
      header   = "X-Content-Type-Options"
      value    = "nosniff"
      override = true
    }
  }

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 63072000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }
}

#
# ECS & Workloads
#

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "example-${var.example_env}"

  # Capacity provider strategy
  default_capacity_provider_strategy = {
    fargate = {
      name   = "FARGATE"
      weight = 70
      base   = 1
    }
    fargate_spot = {
      name   = "FARGATE_SPOT"
      weight = 30
    }
  }
}

resource "aws_lb" "main" {
  name                       = var.example_env
  internal                   = false
  load_balancer_type         = "application"
  subnets                    = module.vpc.public_subnets
  enable_deletion_protection = false
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Nothing here..."
      status_code  = "200"
    }
  }
}

data "aws_route53_zone" "demo" {
  name = "overmind-terraform-example.com."
}

# This database exists so that we can prove that we can discover relationships
# between resources that technically don't know about one another. The example
# here being that there is an ECS service that needs to know the database URL,
# and that database URL is provided as a raw DNS name, we should still be able
# to discover this relationship and therefore tell people about it
resource "aws_db_subnet_group" "default" {
  name       = "main-${var.example_env}"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "Default DB Subnet Group for ${var.example_env}"
  }
}

resource "aws_rds_cluster" "face_database" {
  cluster_identifier           = "facial-recognition-${var.example_env}"
  engine                       = "aurora-postgresql"
  engine_mode                  = "provisioned"
  engine_version               = "16.6"
  database_name                = "face_recognition"
  master_username              = "postgres"
  master_password              = "must_be_eight_characters_long"
  storage_encrypted            = true
  kms_key_id                   = aws_kms_key.database_key.arn
  db_subnet_group_name         = aws_db_subnet_group.default.name
  skip_final_snapshot          = true
  backup_retention_period      = 7
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"

  vpc_security_group_ids = [aws_security_group.database_sg.id]

  enabled_cloudwatch_logs_exports = ["postgresql"]

  final_snapshot_identifier = "test"

  serverlessv2_scaling_configuration {
    max_capacity = 2
    min_capacity = 0.5
  }

  tags = {
    Environment = var.example_env
    Purpose     = "Facial recognition data storage"
    Backup      = "required"
  }
}

# KMS key for database encryption
resource "aws_kms_key" "database_key" {
  description             = "KMS key for RDS encryption in ${var.example_env}"
  deletion_window_in_days = 7

  tags = {
    Name        = "database-key-${var.example_env}"
    Environment = var.example_env
  }
}

resource "aws_kms_alias" "database_key" {
  name          = "alias/rds-${var.example_env}"
  target_key_id = aws_kms_key.database_key.key_id
}

# Security group for database
resource "aws_security_group" "database_sg" {
  name        = "database-sg-${var.example_env}"
  description = "Security group for RDS database"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.vpc.default_security_group_id]
    description     = "PostgreSQL access from ECS services"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "database-sg-${var.example_env}"
    Environment = var.example_env
  }
}

resource "aws_rds_cluster_instance" "face_database" {
  cluster_identifier = aws_rds_cluster.face_database.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.face_database.engine
  engine_version     = aws_rds_cluster.face_database.engine_version
  apply_immediately  = true
}

resource "aws_ecs_task_definition" "face" {
  family                   = "facial-recognition-${var.example_env}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "facial-recognition"
      image     = "harshmanvar/face-detection-tensorjs:slim-amd"
      cpu       = 1024
      memory    = 2048
      essential = true
      healthCheck = {
        command  = ["CMD-SHELL", "wget -q --spider localhost:1234"]
        interval = 30
        retries  = 3
        timeout  = 5
      }
      mountPoints = []
      environment = [
        {
          name  = "DATABASE_URL"
          value = "postgresql://postgres:must_be_eight_characters_long@${aws_rds_cluster_instance.face_database.endpoint}:5432/face_recognition"
        },
        {
          name  = "AWS_REGION"
          value = "eu-west-2"
        },
        {
          name  = "S3_BUCKET"
          value = aws_s3_bucket.data_lake.bucket
        },
        {
          name  = "SQS_QUEUE_URL"
          value = aws_sqs_queue.processing_queue.url
        }
      ]
      portMappings = [
        {
          containerPort = 1234
          appProtocol   = "http"
        }
      ]
      volumesFrom = []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_face.name
          "awslogs-region"        = "eu-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
  ])
}

# IAM roles for ECS tasks
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role-${var.example_env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role-${var.example_env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "ecs-task-policy-${var.example_env}"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.data_lake.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [
          aws_sqs_queue.processing_queue.arn
        ]
      }
    ]
  })
}

# CloudWatch Log Groups for ECS services
resource "aws_cloudwatch_log_group" "ecs_face" {
  name              = "/ecs/facial-recognition-${var.example_env}"
  retention_in_days = 7

  tags = {
    Environment = var.example_env
    Service     = "facial-recognition"
  }
}

resource "aws_cloudwatch_log_group" "ecs_visit_counter" {
  name              = "/ecs/visit-counter-${var.example_env}"
  retention_in_days = 7

  tags = {
    Environment = var.example_env
    Service     = "visit-counter"
  }
}

resource "aws_cloudwatch_log_group" "ecs_analytics" {
  name              = "/ecs/analytics-${var.example_env}"
  retention_in_days = 7

  tags = {
    Environment = var.example_env
    Service     = "analytics"
  }
}

resource "aws_ecs_service" "face" {
  name            = "facial-recognition"
  cluster         = module.ecs.cluster_id
  task_definition = aws_ecs_task_definition.face.arn
  desired_count   = 1

  network_configuration {
    assign_public_ip = false
    security_groups  = [module.vpc.default_security_group_id, aws_security_group.ecs_service_sg.id]
    subnets          = module.vpc.private_subnets
  }

  capacity_provider_strategy {
    base              = 1
    capacity_provider = "FARGATE"
    weight            = 70
  }

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE_SPOT"
    weight            = 30
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.face.arn
    container_name   = "facial-recognition"
    container_port   = 1234
  }

  depends_on = [aws_lb_listener_rule.face]
}

# Security group for ECS services
resource "aws_security_group" "ecs_service_sg" {
  name        = "ecs-service-sg-${var.example_env}"
  description = "Security group for ECS services"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "HTTP traffic from VPC"
  }

  ingress {
    from_port   = 1234
    to_port     = 1234
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Face recognition service port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "ecs-service-sg-${var.example_env}"
    Environment = var.example_env
  }
}

resource "aws_lb_listener_rule" "face" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.face.arn
  }

  condition {
    host_header {
      values = [aws_route53_record.face.name]
    }
  }
}

resource "aws_lb_target_group" "face" {
  name        = "facerec-${var.example_env}"
  port        = 1234
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  health_check {
    enabled           = true
    timeout           = 30
    interval          = 40
    healthy_threshold = 2
  }
}

resource "aws_route53_record" "face" {
  zone_id = data.aws_route53_zone.demo.zone_id
  name    = "face-${var.example_env}.${data.aws_route53_zone.demo.name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.main.dns_name]
}

resource "aws_ecs_task_definition" "visit_counter" {
  family                   = "visit-counter-${var.example_env}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "visit-counter"
      image     = "yeasy/simple-web:latest"
      cpu       = 256
      memory    = 512
      essential = true
      healthCheck = {
        command  = ["CMD-SHELL", "curl -f http://localhost:80 || exit 1"]
        interval = 30
        retries  = 3
        timeout  = 5
      }
      mountPoints = []
      environment = [
        {
          name  = "FACIAL_RECOGNITION_SERVICE"
          value = aws_route53_record.face.name
        },
        {
          name  = "FACIAL_RECOGNITION_SERVICE_USER"
          value = "facerec"
        },
        {
          name  = "ANALYTICS_SERVICE"
          value = aws_route53_record.analytics.name
        }
      ]
      portMappings = [
        {
          containerPort = 80
          appProtocol   = "http"
        }
      ]
      volumesFrom = []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_visit_counter.name
          "awslogs-region"        = "eu-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
  ])
}

resource "aws_ecs_service" "visit_counter" {
  name            = "visit-counter"
  cluster         = module.ecs.cluster_id
  task_definition = aws_ecs_task_definition.visit_counter.arn
  desired_count   = 2

  network_configuration {
    assign_public_ip = false
    security_groups  = [module.vpc.default_security_group_id, aws_security_group.ecs_service_sg.id]
    subnets          = module.vpc.private_subnets
  }

  capacity_provider_strategy {
    base              = 1
    capacity_provider = "FARGATE"
    weight            = 50
  }

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE_SPOT"
    weight            = 50
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.visit_counter.arn
    container_name   = "visit-counter"
    container_port   = 80
  }

  depends_on = [aws_lb_listener_rule.visit_counter]
}

resource "aws_lb_listener_rule" "visit_counter" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.visit_counter.arn
  }

  condition {
    host_header {
      values = [aws_route53_record.visit_counter.name]
    }
  }
}

resource "aws_lb_target_group" "visit_counter" {
  name        = "visit-counter-${var.example_env}"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_route53_record" "visit_counter" {
  zone_id = data.aws_route53_zone.demo.zone_id
  name    = "visits-${var.example_env}.${data.aws_route53_zone.demo.name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.main.dns_name]
}

resource "aws_cloudfront_distribution" "visit_counter" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_route53_record.visit_counter.name
    origin_id   = "visit-counter-ecs"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.1", "TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "visit-counter-ecs"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy     = "allow-all"
    min_ttl                    = 0
    default_ttl                = 3600
    max_ttl                    = 86400
    response_headers_policy_id = aws_cloudfront_response_headers_policy.headers-policy.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

###################
# New Resources   #
###################

# New S3 bucket with versioning and lifecycle policies
resource "aws_s3_bucket" "data_lake" {
  bucket_prefix = "data-lake-${var.example_env}-${random_pet.this.id}"
  force_destroy = true

  tags = {
    Name        = "Data Lake"
    Environment = var.example_env
    Purpose     = "Analytics and data processing"
  }
}

resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    id     = "delete_old_versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  rule {
    id     = "transition_to_ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }
}

# SQS Queues with DLQ
resource "aws_sqs_queue" "processing_dlq" {
  name                      = "processing-dlq-${var.example_env}"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Environment = var.example_env
    Purpose     = "Dead letter queue for failed message processing"
  }
}

resource "aws_sqs_queue" "processing_queue" {
  name                      = "processing-queue-${var.example_env}"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 345600 # 4 days
  receive_wait_time_seconds = 10

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.processing_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Environment = var.example_env
    Purpose     = "Main processing queue for image analysis"
  }
}

# Lambda function for processing
resource "aws_iam_role" "lambda_processing_role" {
  name = "lambda-processing-${var.example_env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_processing_policy" {
  name = "lambda-processing-policy-${var.example_env}"
  role = aws_iam_role.lambda_processing_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [
          aws_sqs_queue.processing_queue.arn,
          aws_sqs_queue.processing_dlq.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.data_lake.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBClusters",
          "rds:DescribeDBInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "lambda_processing_zip" {
  type        = "zip"
  output_path = "${path.module}/tmp/processing_lambda.zip"

  source {
    content  = <<EOF
import json
import boto3
import urllib.parse

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    
    print(f"Processing {len(event['Records'])} records")
    
    for record in event['Records']:
        # Parse SQS message
        body = json.loads(record['body'])
        print(f"Processing message: {body}")
        
        # Simulate some processing
        # In a real scenario, this would process images, analyze data, etc.
        
        # Store results in data lake
        result = {
            'processedAt': context.aws_request_id,
            'status': 'completed',
            'metadata': body
        }
        
        s3.put_object(
            Bucket='${aws_s3_bucket.data_lake.bucket}',
            Key=f'processed/{context.aws_request_id}.json',
            Body=json.dumps(result),
            ContentType='application/json'
        )
    
    return {
        'statusCode': 200,
        'body': json.dumps(f'Successfully processed {len(event["Records"])} messages')
    }
EOF
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "processing_function" {
  function_name    = "image-processor-${var.example_env}"
  filename         = data.archive_file.lambda_processing_zip.output_path
  source_code_hash = data.archive_file.lambda_processing_zip.output_base64sha256
  role             = aws_iam_role.lambda_processing_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  timeout          = 30

  environment {
    variables = {
      DATA_LAKE_BUCKET = aws_s3_bucket.data_lake.bucket
      ENVIRONMENT      = var.example_env
    }
  }

  tags = {
    Environment = var.example_env
    Purpose     = "Process images and store results in data lake"
  }
}

# Event source mapping for SQS to Lambda
resource "aws_lambda_event_source_mapping" "sqs_lambda_trigger" {
  event_source_arn = aws_sqs_queue.processing_queue.arn
  function_name    = aws_lambda_function.processing_function.arn
  batch_size       = 10

  depends_on = [aws_iam_role_policy.lambda_processing_policy]
}

# Additional ECS service for analytics
resource "aws_ecs_task_definition" "analytics" {
  family                   = "analytics-${var.example_env}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "analytics-service"
      image     = "nginx:alpine"
      cpu       = 512
      memory    = 1024
      essential = true
      healthCheck = {
        command  = ["CMD-SHELL", "curl -f http://localhost:80 || exit 1"]
        interval = 30
        retries  = 3
        timeout  = 5
      }
      environment = [
        {
          name  = "SERVICE_NAME"
          value = "analytics"
        },
        {
          name  = "DATA_LAKE_BUCKET"
          value = aws_s3_bucket.data_lake.bucket
        },
        {
          name  = "PROCESSING_QUEUE_URL"
          value = aws_sqs_queue.processing_queue.url
        },
        {
          name  = "DATABASE_ENDPOINT"
          value = aws_rds_cluster.face_database.endpoint
        }
      ]
      portMappings = [
        {
          containerPort = 80
          appProtocol   = "http"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_analytics.name
          "awslogs-region"        = "eu-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "analytics" {
  name            = "analytics"
  cluster         = module.ecs.cluster_id
  task_definition = aws_ecs_task_definition.analytics.arn
  desired_count   = 1

  network_configuration {
    assign_public_ip = false
    security_groups  = [module.vpc.default_security_group_id, aws_security_group.ecs_service_sg.id]
    subnets          = module.vpc.private_subnets
  }

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.analytics.arn
    container_name   = "analytics-service"
    container_port   = 80
  }

  depends_on = [aws_lb_listener_rule.analytics]
}

resource "aws_lb_target_group" "analytics" {
  name        = "analytics-${var.example_env}"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  health_check {
    enabled           = true
    timeout           = 30
    interval          = 40
    healthy_threshold = 2
    path              = "/"
  }
}

resource "aws_lb_listener_rule" "analytics" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 98

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.analytics.arn
  }

  condition {
    host_header {
      values = [aws_route53_record.analytics.name]
    }
  }
}

resource "aws_route53_record" "analytics" {
  zone_id = data.aws_route53_zone.demo.zone_id
  name    = "analytics-${var.example_env}.${data.aws_route53_zone.demo.name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.main.dns_name]
}

# EventBridge rule to trigger processing
resource "aws_cloudwatch_event_rule" "s3_object_created" {
  name        = "s3-object-created-${var.example_env}"
  description = "Trigger processing when objects are created in data lake"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.data_lake.bucket]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "sqs_target" {
  rule      = aws_cloudwatch_event_rule.s3_object_created.name
  target_id = "SendToSQS"
  arn       = aws_sqs_queue.processing_queue.arn
}

# SQS queue policy to allow EventBridge
resource "aws_sqs_queue_policy" "processing_queue_policy" {
  queue_url = aws_sqs_queue.processing_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgeToSendMessage"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.processing_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.s3_object_created.arn
          }
        }
      }
    ]
  })
}
