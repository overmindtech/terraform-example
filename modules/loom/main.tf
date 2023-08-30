locals {
  domain_name = "terraform-aws-modules.modules.tf" # trimsuffix(data.aws_route53_zone.this.name, ".")
  subdomain   = "cdn"
}

module "cloudfront" {
  source = "terraform-aws-modules/cloudfront/aws"
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

    lambda_function_association = {

      # Valid keys: viewer-request, origin-request, viewer-response, origin-response
      viewer-request = {
        lambda_arn   = module.lambda_function.lambda_function_qualified_arn
        include_body = true
      }

      origin-request = {
        lambda_arn = module.lambda_function.lambda_function_qualified_arn
      }
    }
  }

  ordered_cache_behavior = [
    {
      path_pattern           = "/static/*"
      target_origin_id       = "s3_one"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true
      query_string    = true
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
  version = "~> 3.0"

  bucket        = "s3-one-${random_pet.this.id}"
  force_destroy = true
}

#############################################
# Using packaged function from Lambda module
#############################################

locals {
  package_url = "https://raw.githubusercontent.com/terraform-aws-modules/terraform-aws-lambda/master/examples/fixtures/python3.8-zip/existing_package.zip"
  downloaded  = "downloaded_package_${md5(local.package_url)}.zip"
}

resource "null_resource" "download_package" {
  triggers = {
    downloaded = local.downloaded
  }

  provisioner "local-exec" {
    command = "curl -L -o ${local.downloaded} ${local.package_url}"
  }
}

module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 4.0"

  function_name = "${random_pet.this.id}-lambda"
  description   = "My awesome lambda function"
  handler       = "index.lambda_handler"
  runtime       = "python3.8"

  publish        = true
  lambda_at_edge = true

  create_package         = false
  local_existing_package = local.downloaded

  # @todo: Missing CloudFront as allowed_triggers?

  #    allowed_triggers = {
  #      AllowExecutionFromAPIGateway = {
  #        service = "apigateway"
  #        arn     = module.api_gateway.apigatewayv2_api_execution_arn
  #      }
  #    }
}

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
  bucket = aws_s3_bucket.b.id
  acl    = "private"
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
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id
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
    access_control_allow_credentials = true

    access_control_allow_headers {
      items = ["test"]
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
