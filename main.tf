
resource "aws_s3_bucket" "new_bucket" {
  bucket = "overmind-terraform-example-new-bucket"
}

resource "aws_s3_bucket_lifecycle_configuration" "example" {
  bucket = aws_s3_bucket.new_bucket.id

  rule {
    id = "rule-1"

    filter {}

    status = "Enabled"
  }
}
