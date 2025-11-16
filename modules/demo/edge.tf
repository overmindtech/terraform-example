resource "aws_cloudfront_origin_access_control" "static" {
  name                              = "${local.name_prefix}-oac"
  description                       = "Access control for static bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_iam_policy_document" "static_bucket_policy" {
  statement {
    actions = ["s3:GetObject"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    resources = ["${aws_s3_bucket.static_site.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "static_site" {
  bucket = aws_s3_bucket.static_site.id
  policy = data.aws_iam_policy_document.static_bucket_policy.json
}

resource "aws_wafv2_web_acl" "cloudfront" {
  provider = aws.us_east_1
  name     = "${local.name_prefix}-waf"
  scope    = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "ManagedIPs"
    priority = 1

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesAmazonIpReputationList"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-waf-ip"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"
  comment             = "Low-cost demo stack"
  web_acl_id          = aws_wafv2_web_acl.cloudfront.arn

  origin {
    domain_name = aws_s3_bucket.static_site.bucket_regional_domain_name
    origin_id   = "static-site"

    origin_access_control_id = aws_cloudfront_origin_access_control.static.id
  }

  origin {
    domain_name = replace(aws_apigatewayv2_api.recipes.api_endpoint, "https://", "")
    origin_id   = "api-gateway"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "static-site"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "api-gateway"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["Authorization"]
      cookies {
        forward = "none"
      }
    }
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.tags
}
