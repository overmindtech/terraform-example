# Message Size Limit Breach Scenario
# This demonstrates how increasing SQS message size can break Lambda batch processing

# SQS Queue for image processing
resource "aws_sqs_queue" "image_processing_queue" {
  name = "image-processing-${var.example_env}"
  
  # This is the configuration that looks innocent but will break Lambda
  max_message_size = var.max_message_size  # 25KB (safe) vs 100KB (dangerous)
  
  # Standard queue configuration
  message_retention_seconds  = 1209600  # 14 days
  visibility_timeout_seconds = 30
  receive_wait_time_seconds  = 20       # Long polling
  
  # Dead letter queue for failed messages
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.image_processing_dlq.arn
    maxReceiveCount     = 3
  })
  
  tags = {
    Name        = "Image Processing Queue"
    Environment = var.example_env
    Scenario    = "Message Size Breach"
  }
}

# Dead Letter Queue for failed messages
resource "aws_sqs_queue" "image_processing_dlq" {
  name = "image-processing-dlq-${var.example_env}"
  
  message_retention_seconds = 1209600  # 14 days
  
  tags = {
    Name        = "Image Processing DLQ"
    Environment = var.example_env
    Scenario    = "Message Size Breach"
  }
}

# Lambda function for processing images
resource "aws_lambda_function" "image_processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "image-processor-${var.example_env}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = var.lambda_timeout
  
  # This will fail when batch size × message size > 256KB (Lambda async limit)
  memory_size = 1024
  
  depends_on = [
    aws_iam_role.lambda_role
  ]
  
  
  tags = {
    Name        = "Image Processor"
    Environment = var.example_env
    Scenario    = "Message Size Breach"
  }
}

# SQS trigger for Lambda - This is where the disaster happens
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.image_processing_queue.arn
  function_name    = aws_lambda_function.image_processor.arn
  
  # This batch size combined with large messages will exceed Lambda limits
  batch_size = var.batch_size  # 10 messages × 100KB = 1MB > 256KB Lambda async limit!
  
  # These settings make the failure more dramatic
  maximum_batching_window_in_seconds = 5
  maximum_retry_attempts            = 3
  
  depends_on = [aws_iam_role_policy_attachment.lambda_sqs_policy]
}


# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/image-processor-${var.example_env}"
  retention_in_days = 14
  
  tags = {
    Name        = "Lambda Logs"
    Environment = var.example_env
    Scenario    = "Message Size Breach"
  }
}

# CloudWatch Alarm for Lambda errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "lambda-errors-${var.example_env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This alarm monitors Lambda function errors"
  
  dimensions = {
    FunctionName = aws_lambda_function.image_processor.function_name
  }
  
  tags = {
    Name        = "Lambda Errors Alarm"
    Environment = var.example_env
    Scenario    = "Message Size Breach"
  }
}

# CloudWatch Alarm for SQS queue depth
resource "aws_cloudwatch_metric_alarm" "sqs_queue_depth" {
  alarm_name          = "sqs-queue-depth-${var.example_env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfVisibleMessages"
  namespace           = "AWS/SQS"
  period              = "60"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "This alarm monitors SQS queue depth"
  
  dimensions = {
    QueueName = aws_sqs_queue.image_processing_queue.name
  }
  
  tags = {
    Name        = "SQS Queue Depth Alarm"
    Environment = var.example_env
    Scenario    = "Message Size Breach"
  }
}
