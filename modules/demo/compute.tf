data "archive_file" "api" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/api_handler"
  output_path = "${path.module}/lambda/api_handler.zip"
}

data "archive_file" "ingest" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/ingest_handler"
  output_path = "${path.module}/lambda/ingest_handler.zip"
}

data "archive_file" "pipeline" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/pipeline_handler"
  output_path = "${path.module}/lambda/pipeline_handler.zip"
}

data "archive_file" "presign" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/presign_handler"
  output_path = "${path.module}/lambda/presign_handler.zip"
}

data "archive_file" "authorizer" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/authorizer"
  output_path = "${path.module}/lambda/authorizer.zip"
}

data "archive_file" "slack" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/slack_notifier"
  output_path = "${path.module}/lambda/slack_notifier.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  for_each          = toset(["api", "ingest", "pipeline", "authorizer", "slack", "presign"])
  name              = "/aws/lambda/${local.name_prefix}-${each.value}"
  retention_in_days = 14
  tags              = local.tags
}

resource "aws_lambda_function" "api" {
  function_name    = "${local.name_prefix}-api"
  filename         = data.archive_file.api.output_path
  source_code_hash = data.archive_file.api.output_base64sha256
  handler          = "app.handler"
  runtime          = "python3.11"
  role             = aws_iam_role.lambda.arn
  timeout          = 15
  memory_size      = 256
  tags             = local.tags

  vpc_config {
    subnet_ids         = [for s in aws_subnet.private : s.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      PROJECT_NAME  = local.name_prefix
      RECIPES_TABLE = aws_dynamodb_table.recipes.name
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
}

resource "aws_lambda_function" "ingest" {
  function_name    = "${local.name_prefix}-ingest"
  filename         = data.archive_file.ingest.output_path
  source_code_hash = data.archive_file.ingest.output_base64sha256
  handler          = "app.handler"
  runtime          = "python3.11"
  role             = aws_iam_role.lambda.arn
  timeout          = 30
  memory_size      = 256
  tags             = local.tags

  vpc_config {
    subnet_ids         = [for s in aws_subnet.private : s.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      RECIPES_TABLE     = aws_dynamodb_table.recipes.name
      ASSETS_TABLE      = aws_dynamodb_table.assets.name
      STATE_MACHINE_ARN = aws_sfn_state_machine.asset_pipeline.arn
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
}

resource "aws_lambda_function" "pipeline" {
  function_name    = "${local.name_prefix}-pipeline"
  filename         = data.archive_file.pipeline.output_path
  source_code_hash = data.archive_file.pipeline.output_base64sha256
  handler          = "app.handler"
  runtime          = "python3.11"
  role             = aws_iam_role.lambda.arn
  timeout          = 60
  memory_size      = 512
  tags             = local.tags

  vpc_config {
    subnet_ids         = [for s in aws_subnet.private : s.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      ASSETS_TABLE   = aws_dynamodb_table.assets.name
      EVENT_BUS_NAME = aws_cloudwatch_event_bus.pipeline.name
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
}

resource "aws_lambda_function" "authorizer" {
  function_name    = "${local.name_prefix}-authorizer"
  filename         = data.archive_file.authorizer.output_path
  source_code_hash = data.archive_file.authorizer.output_base64sha256
  handler          = "app.handler"
  runtime          = "python3.11"
  role             = aws_iam_role.lambda.arn
  timeout          = 5
  memory_size      = 128
  tags             = local.tags

  environment {
    variables = {
      SHARED_SECRET = "demo-secret"
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
}

resource "aws_lambda_function" "slack" {
  function_name    = "${local.name_prefix}-slack"
  filename         = data.archive_file.slack.output_path
  source_code_hash = data.archive_file.slack.output_base64sha256
  handler          = "app.handler"
  runtime          = "python3.11"
  role             = aws_iam_role.lambda.arn
  timeout          = 10
  memory_size      = 128
  tags             = local.tags

  environment {
    variables = {
      SLACK_WEBHOOK_PARAMETER = aws_ssm_parameter.slack_webhook.name
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
}

resource "aws_lambda_function" "presign" {
  function_name    = "${local.name_prefix}-presign"
  filename         = data.archive_file.presign.output_path
  source_code_hash = data.archive_file.presign.output_base64sha256
  handler          = "app.handler"
  runtime          = "python3.11"
  role             = aws_iam_role.lambda.arn
  timeout          = 10
  memory_size      = 256
  tags             = local.tags

  environment {
    variables = {
      UPLOADS_BUCKET = aws_s3_bucket.uploads.bucket
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
}

resource "aws_s3_bucket_notification" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  topic {
    topic_arn = aws_sns_topic.asset_ingest.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.ingest_sns]
}

resource "aws_sns_topic_subscription" "ingest" {
  topic_arn = aws_sns_topic.asset_ingest.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.ingest.arn
}

resource "aws_lambda_permission" "ingest_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingest.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.asset_ingest.arn
}

resource "aws_sfn_state_machine" "asset_pipeline" {
  name     = "${local.name_prefix}-pipeline"
  role_arn = aws_iam_role.step_functions.arn

  definition = jsonencode({
    Comment = "Serverless asset pipeline"
    StartAt = "VirusScan"
    States = {
      VirusScan = {
        Type     = "Task"
        Resource = aws_lambda_function.pipeline.arn
        Next     = "AssetMetadata"
        Parameters = {
          "asset_id.$"   = "$.asset_id"
          "bucket.$"     = "$.bucket"
          "object_key.$" = "$.object_key"
        }
      }
      AssetMetadata = {
        Type     = "Task"
        Resource = aws_lambda_function.pipeline.arn
        End      = true
      }
    }
  })
  tags = local.tags
}

resource "aws_cloudwatch_event_bus" "pipeline" {
  name = "${local.name_prefix}-bus"
  tags = local.tags
}

resource "aws_cloudwatch_event_rule" "asset_processed" {
  name           = "${local.name_prefix}-asset-processed"
  event_bus_name = aws_cloudwatch_event_bus.pipeline.name

  event_pattern = jsonencode({
    "detail-type" = ["AssetProcessed"]
    source        = ["demo.asset.pipeline"]
  })
}

resource "aws_cloudwatch_event_target" "asset_processed_slack" {
  rule           = aws_cloudwatch_event_rule.asset_processed.name
  event_bus_name = aws_cloudwatch_event_bus.pipeline.name
  arn            = aws_lambda_function.slack.arn
}

resource "aws_lambda_permission" "eventbridge_to_slack" {
  statement_id  = "AllowEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.asset_processed.arn
}

resource "aws_cloudwatch_event_target" "asset_processed_queue" {
  rule           = aws_cloudwatch_event_rule.asset_processed.name
  event_bus_name = aws_cloudwatch_event_bus.pipeline.name
  arn            = aws_sqs_queue.asset_events.arn
}

resource "aws_sqs_queue_policy" "asset_events" {
  queue_url = aws_sqs_queue.asset_events.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowEventBridge"
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.asset_events.arn
        Condition = {
          ArnEquals = { "aws:SourceArn" = aws_cloudwatch_event_rule.asset_processed.arn }
        }
      }
    ]
  })
}

