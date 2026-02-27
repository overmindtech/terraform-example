# =============================================================================
# Loom CDN Incident Replication
# =============================================================================
#
# Step 1: terraform init && terraform apply   (deploys the SAFE config)
# Step 2: Run ./test.sh                       (confirm no session leak)
# Step 3: Comment out the "BEFORE" block and uncomment the "AFTER" block
#         in the default_cache_behavior below, then terraform apply again
# Step 4: Run ./test.sh                       (confirm session leak)
# Step 5: terraform destroy
# =============================================================================

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "loom-replication"
}

# -----------------------------------------------------------------------------
# Lambda function — simulates Loom's rolling session app server
# -----------------------------------------------------------------------------

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "app" {
  function_name    = "${var.prefix}-app"
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 10
}

resource "aws_lambda_function_url" "app" {
  function_name      = aws_lambda_function.app.function_name
  authorization_type = "NONE"
}

resource "aws_iam_role" "lambda" {
  name = "${var.prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# -----------------------------------------------------------------------------
# CloudFront cache policy — 1 second TTL, no cookies in cache key
# (Used by both BEFORE and AFTER configs)
# -----------------------------------------------------------------------------
resource "aws_cloudfront_cache_policy" "static_assets" {
  name        = "${var.prefix}-static-cache"
  comment     = "1s cache, no cookies in key"
  min_ttl     = 1
  default_ttl = 1
  max_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

# -----------------------------------------------------------------------------
# Origin request policy — forwards ALL cookies and headers to the origin.
# This is what "passed on more headers" means. Only used by the AFTER config.
# -----------------------------------------------------------------------------
resource "aws_cloudfront_origin_request_policy" "forward_all" {
  name    = "${var.prefix}-forward-all"
  comment = "Forwards all viewer values to origin"

  cookies_config {
    cookie_behavior = "all"
  }
  headers_config {
    header_behavior = "none"
  }
  query_strings_config {
    query_string_behavior = "none"
  }
}

# -----------------------------------------------------------------------------
# CloudFront distribution
# -----------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "app" {
  enabled              = true
  comment              = "${var.prefix} — Loom session leak replication"
  is_ipv6_enabled      = true
  wait_for_deployment  = true

  origin {
    domain_name = replace(replace(aws_lambda_function_url.app.function_url, "https://", ""), "/", "")
    origin_id   = "lambda-app"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # ===========================================================================
  # BEFORE: The safe config (deprecated forwarded_values)
  #
  # cookies { forward = "none" } does three things at once:
  #   1. Strips Cookie from requests to origin
  #   2. Strips Set-Cookie from cached responses
  #   3. Excludes cookies from the cache key
  #
  # To switch to the dangerous AFTER config:
  #   1. Comment out this entire default_cache_behavior block
  #   2. Uncomment the AFTER block below
  #   3. terraform apply
  # ===========================================================================
  # default_cache_behavior {
  #   allowed_methods        = ["GET", "HEAD", "OPTIONS"]
  #   cached_methods         = ["GET", "HEAD"]
  #   target_origin_id       = "lambda-app"
  #   viewer_protocol_policy = "allow-all"

  #   forwarded_values {
  #     query_string = false
  #     cookies {
  #       forward = "none"
  #     }
  #   }

  #   min_ttl     = 1
  #   default_ttl = 1
  #   max_ttl     = 1
  # }

  # ===========================================================================
  # AFTER: The dangerous config (cache policy + origin request policy)
  #
  # This is the migration Loom made. The cache policy looks equivalent to
  # forward="none" but the origin request policy forwards ALL cookies to the
  # origin. This means:
  #   - Origin sees session cookies → returns Set-Cookie
  #   - CloudFront caches Set-Cookie (because cookies are "configured")
  #   - Cache key has no cookies → all users share the same cached response
  #   - User B gets User A's session cookie = session hijacking
  #
  # To activate: uncomment this block and comment out the BEFORE block above.
  # ===========================================================================
  default_cache_behavior {
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "lambda-app"
    viewer_protocol_policy   = "allow-all"
    cache_policy_id          = aws_cloudfront_cache_policy.static_assets.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.forward_all.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.app.domain_name}"
}

output "lambda_url" {
  value = aws_lambda_function_url.app.function_url
}
