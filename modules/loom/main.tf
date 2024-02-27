locals {
  domain_name = "terraform-aws-modules.modules.tf" # trimsuffix(data.aws_route53_zone.this.name, ".")
  subdomain   = "cdn"
}

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
    s3_oac = {
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
      origin_access_control = "s3_oac" # key in `origin_access_control`
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

  bucket        = "s3-one-${random_pet.this.id}"
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
  name    = "example-${random_pet.this.id}"
  runtime = "cloudfront-js-1.0"
  code    = file("example-function.js")
}

# Second resource

resource "aws_s3_bucket" "b" {
  bucket = "second-example-${random_pet.second.id}"

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
  name                              = "example"
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
  name    = "security-policy"
  comment = "This inforces some appliction-source security headers"

  cors_config {
    access_control_allow_credentials = false

    access_control_allow_headers {
      items = ["X-Example-Header"]
    }

    access_control_allow_methods {
      items = ["GET"]
    }

    access_control_allow_origins {
      items = ["test.example.comtest"]
    }

    origin_override = true
  }
}

#
# ECS & Workloads
#

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "workloads"
  cidr = "10.0.0.0/16"

  default_security_group_egress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "ALL"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  default_security_group_ingress = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 1234
      to_port     = 1234
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  azs             = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "example"

  # Capacity provider
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }
}

resource "aws_lb" "main" {
  name                       = "main"
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


resource "aws_ecs_task_definition" "face" {
  family                   = "facial-recognition"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048

  container_definitions = jsonencode([
    {
      name      = "facial-recognition"
      image     = "harshmanvar/face-detection-tensorjs:slim-amd"
      cpu       = 1024
      memory    = 2048
      essential = true
      healthCheck = {
        command  = ["CMD-SHELL", "wget -q --spider localhost:80"]
        interval = 30
        retries  = 3
        timeout  = 5
      }
      mountPoints = []
      environment = []
      portMappings = [
        {
          containerPort = 1234
          appProtocol   = "http"
        }
      ]
      volumesFrom = []
    },
  ])
}

resource "aws_ecs_service" "face" {
  name            = "facial-recognition"
  cluster         = module.ecs.cluster_id
  task_definition = aws_ecs_task_definition.face.arn
  desired_count   = 1

  network_configuration {
    assign_public_ip = false
    security_groups  = [module.vpc.default_security_group_id]
    subnets          = module.vpc.private_subnets
  }

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE"
    weight            = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.face.arn
    container_name   = "facial-recognition"
    container_port   = 1234
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
  name        = "facial-recognition"
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
  name    = "face.${data.aws_route53_zone.demo.name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.main.dns_name]
}

resource "aws_ecs_task_definition" "visit_counter" {
  family                   = "visit-counter"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512

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
      environment = []
      portMappings = [
        {
          containerPort = 80
          appProtocol   = "http"
        }
      ]
      volumesFrom = []
    },
  ])
}

resource "aws_ecs_service" "visit_counter" {
  name            = "visit-counter"
  cluster         = module.ecs.cluster_id
  task_definition = aws_ecs_task_definition.visit_counter.arn
  desired_count   = 1

  network_configuration {
    assign_public_ip = false
    security_groups  = [module.vpc.default_security_group_id]
    subnets          = module.vpc.private_subnets
  }

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE"
    weight            = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.visit_counter.arn
    container_name   = "visit-counter"
    container_port   = 80
  }
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
  name        = "visit-counter"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_route53_record" "visit_counter" {
  zone_id = data.aws_route53_zone.demo.zone_id
  name    = "visits.${data.aws_route53_zone.demo.name}"
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
