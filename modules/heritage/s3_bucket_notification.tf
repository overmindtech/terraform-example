resource "aws_s3_bucket" "my_bucket" {
  bucket_prefix = "bucket-notification-${var.example_env}"
  acl           = "private"
}
resource "aws_sqs_queue" "my_queue" {
  name = "-${var.example_env}-notifications-from-s3"
}
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.my_bucket.id

  queue {
    queue_arn = aws_sqs_queue.my_queue.arn
    events    = ["s3:ObjectCreated:*"]
    # Optionally specify a filter
    # filter_prefix = "logs/"
    # filter_suffix = ".log"
  }
}
resource "aws_sqs_queue_policy" "my_queue_policy" {
  queue_url = aws_sqs_queue.my_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${aws_sqs_queue.my_queue.arn}/SQSPolicy"
    Statement = [
      {
        Sid       = "AllowS3BucketNotification"
        Effect    = "Allow"
        Principal = "*"
        Action    = "SQS:SendMessage"
        Resource  = aws_sqs_queue.my_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_s3_bucket.my_bucket.arn
          }
        }
      },
    ]
  })
}

