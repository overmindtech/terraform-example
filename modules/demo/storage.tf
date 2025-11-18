resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "aws_s3_bucket" "static_site" {
  bucket = "${local.name_prefix}-static-${random_string.suffix.result}"
  tags   = merge(local.tags, { Purpose = "static-site" })
}

resource "aws_s3_bucket_versioning" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  rule {
    id     = "static-ia"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

resource "aws_s3_bucket_public_access_block" "static_site" {
  bucket                  = aws_s3_bucket.static_site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "uploads" {
  bucket = "${local.name_prefix}-uploads-${random_string.suffix.result}"
  tags   = merge(local.tags, { Purpose = "ingest" })
}

resource "aws_s3_bucket_versioning" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    id     = "ingest-cleanup"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket                  = aws_s3_bucket.uploads.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "processed" {
  bucket = "${local.name_prefix}-processed-${random_string.suffix.result}"
  tags   = merge(local.tags, { Purpose = "processed-assets" })
}

resource "aws_s3_bucket_versioning" "processed" {
  bucket = aws_s3_bucket.processed.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "processed" {
  bucket = aws_s3_bucket.processed.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "processed" {
  bucket = aws_s3_bucket.processed.id

  rule {
    id     = "processed-ia"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "processed" {
  bucket                  = aws_s3_bucket.processed.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_sns_topic" "asset_ingest" {
  name = "${local.name_prefix}-asset-ingest"
  tags = local.tags
}

resource "aws_sns_topic_policy" "asset_ingest" {
  arn = aws_sns_topic.asset_ingest.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3Publish"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.asset_ingest.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_s3_bucket.uploads.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue" "asset_events" {
  name                       = "${local.name_prefix}-asset-events"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 86400
  tags                       = local.tags
}

resource "aws_dynamodb_table" "recipes" {
  name         = "${local.name_prefix}-recipes"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(local.tags, { Purpose = "recipes" })
}

resource "aws_dynamodb_table" "assets" {
  name         = "${local.name_prefix}-assets"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "asset_id"

  attribute {
    name = "asset_id"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  global_secondary_index {
    name            = "status-index"
    hash_key        = "status"
    projection_type = "ALL"
  }

  attribute {
    name = "status"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(local.tags, { Purpose = "asset-metadata" })
}

resource "random_password" "aurora" {
  length  = 20
  special = true
}

resource "aws_secretsmanager_secret" "aurora_credentials" {
  name = "${local.name_prefix}/aurora"
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "aurora_credentials" {
  secret_id     = aws_secretsmanager_secret.aurora_credentials.id
  secret_string = jsonencode({ username = "app_admin", password = random_password.aurora.result })
}

resource "aws_db_subnet_group" "aurora" {
  name       = "${local.name_prefix}-aurora"
  subnet_ids = [for s in aws_subnet.private : s.id]

  tags = merge(local.tags, { Name = "${local.name_prefix}-aurora-subnets" })
}

resource "aws_rds_cluster_parameter_group" "aurora" {
  name        = "${local.name_prefix}-aurora"
  family      = "aurora-postgresql17"
  description = "Enable pg_trgm and force SSL"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = local.tags
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier              = "${local.name_prefix}-aurora"
  engine                          = "aurora-postgresql"
  engine_version                  = "17.5"
  engine_mode                     = "provisioned"
  database_name                   = "recipes"
  master_username                 = jsondecode(aws_secretsmanager_secret_version.aurora_credentials.secret_string)["username"]
  master_password                 = jsondecode(aws_secretsmanager_secret_version.aurora_credentials.secret_string)["password"]
  db_subnet_group_name            = aws_db_subnet_group.aurora.name
  vpc_security_group_ids          = [aws_security_group.rds.id]
  storage_encrypted               = true
  skip_final_snapshot             = true
  apply_immediately               = true
  deletion_protection             = false
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora.name
  enable_http_endpoint            = true

  serverlessv2_scaling_configuration {
    min_capacity = var.aurora_min_acus
    max_capacity = var.aurora_max_acus
  }

  tags = merge(local.tags, { Purpose = "aurora" })
}

resource "aws_rds_cluster_instance" "aurora" {
  identifier         = "${local.name_prefix}-aurora-instance"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora.engine

  tags = merge(local.tags, { Purpose = "aurora" })
}

