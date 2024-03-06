data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/tmp/lambda_function.zip"

  source {
    content  = <<EOF
exports.handler = async (event) => {
  console.log("Event: ", event);
  return {
    statusCode: 200,
    body: JSON.stringify('Hello from Lambda!'),
  };
};
EOF
    filename = "index.js"
  }
}

resource "aws_iam_role" "lambda_iam_role" {
  name = "example_lambda_iam_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com",
        },
        Effect = "Allow",
        Sid = "",
      },
    ],
  })
}

resource "aws_lambda_function" "example" {
  function_name = "example_lambda_function"
  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  role          = aws_iam_role.lambda_iam_role.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x"
}

resource "aws_sns_topic" "example_topic" {
  name = "example-topic"
}

# resource "aws_lambda_permission" "allow_sns" {
#   statement_id  = "AllowExecutionFromSNS"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.example.function_name
#   principal     = "sns.amazonaws.com"
#   source_arn    = aws_sns_topic.example_topic.arn
# }