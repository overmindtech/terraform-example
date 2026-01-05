# =============================================================================
# AWS Compute Resources
# Scale Testing Infrastructure for Overmind
# =============================================================================
# Creates EC2 instances (stopped) and Lambda functions.
# EC2 instances are created and then stopped to minimize costs.
# =============================================================================

# -----------------------------------------------------------------------------
# EC2 Instances (Stopped)
# -----------------------------------------------------------------------------

resource "aws_instance" "scale_test" {
  count = var.enable_ec2 ? local.regional_count.ec2_instances : 0

  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = var.ec2_instance_type
  subnet_id            = aws_subnet.public[count.index % length(aws_subnet.public)].id
  iam_instance_profile = aws_iam_instance_profile.ec2.name

  # Use shared security groups (creates relationship density)
  vpc_security_group_ids = [
    aws_security_group.shared[count.index % length(aws_security_group.shared)].id
  ]

  # Minimal EBS volume
  root_block_device {
    volume_size           = var.ebs_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  # User data that does nothing (instance will be stopped)
  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "Scale test instance ${count.index + 1}"
  EOF
  )

  tags = merge(var.common_tags, {
    Name  = "${local.name_prefix}-ec2-${count.index + 1}"
    Index = count.index + 1
  })

  # Lifecycle: We want these instances to be stopped after creation
  # Note: Terraform doesn't have a native way to stop instances,
  # so we use a null_resource with local-exec to stop them
}

# Stop EC2 instances after creation (cost optimization)
resource "null_resource" "stop_instances" {
  count = var.enable_ec2 ? local.regional_count.ec2_instances : 0

  triggers = {
    instance_id = aws_instance.scale_test[count.index].id
  }

  provisioner "local-exec" {
    command = <<-EOF
      aws ec2 stop-instances --instance-ids ${aws_instance.scale_test[count.index].id} --region ${var.region} || true
    EOF
  }

  depends_on = [aws_instance.scale_test]
}

# -----------------------------------------------------------------------------
# Lambda Functions
# -----------------------------------------------------------------------------

# Create a simple Lambda deployment package
data "archive_file" "lambda_dummy" {
  type        = "zip"
  output_path = "${path.module}/lambda_dummy.zip"

  source {
    content  = <<-EOF
      exports.handler = async (event) => {
        console.log('Scale test Lambda invoked', JSON.stringify(event));
        return {
          statusCode: 200,
          body: JSON.stringify({ message: 'Scale test Lambda', region: process.env.AWS_REGION })
        };
      };
    EOF
    filename = "index.js"
  }
}

resource "aws_lambda_function" "scale_test" {
  count = var.enable_lambda ? local.regional_count.lambda_functions : 0

  function_name = "${local.name_prefix}-fn-${count.index + 1}"
  description   = "Scale test Lambda function ${count.index + 1}"

  filename         = data.archive_file.lambda_dummy.output_path
  source_code_hash = data.archive_file.lambda_dummy.output_base64sha256
  handler          = "index.handler"
  runtime          = "nodejs20.x"

  # Use shared IAM roles (creates relationship density)
  role = aws_iam_role.lambda_execution[count.index % length(aws_iam_role.lambda_execution)].arn

  memory_size = var.lambda_memory
  timeout     = var.lambda_timeout

  # Environment variables that reference other resources
  environment {
    variables = {
      REGION           = var.region
      SCALE_INDEX      = tostring(count.index + 1)
      SCALE_MULTIPLIER = tostring(var.scale_multiplier)
      # Reference to SNS topic (creates cross-service edge)
      SNS_TOPIC_ARN = aws_sns_topic.scale_test[count.index % length(aws_sns_topic.scale_test)].arn
      # Reference to SQS queue (creates cross-service edge)
      SQS_QUEUE_URL = aws_sqs_queue.scale_test[count.index % length(aws_sqs_queue.scale_test)].url
    }
  }

  tags = merge(var.common_tags, {
    Name  = "${local.name_prefix}-fn-${count.index + 1}"
    Index = count.index + 1
  })

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy_attachment.cross_service,
    aws_cloudwatch_log_group.lambda
  ]
}

# -----------------------------------------------------------------------------
# CloudWatch Log Groups for Lambda
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "lambda" {
  count = var.enable_lambda ? local.regional_count.lambda_functions : 0

  name              = "/aws/lambda/${local.name_prefix}-fn-${count.index + 1}"
  retention_in_days = 1 # Minimal retention for cost savings

  tags = merge(var.common_tags, {
    Name  = "${local.name_prefix}-logs-fn-${count.index + 1}"
    Index = count.index + 1
  })
}

# -----------------------------------------------------------------------------
# Additional CloudWatch Log Groups (non-Lambda)
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "scale_test" {
  count = local.regional_count.log_groups

  name              = "/ovm-scale/${var.region}/test-${count.index + 1}"
  retention_in_days = 1 # Minimal retention for cost savings

  tags = merge(var.common_tags, {
    Name  = "${local.name_prefix}-logs-${count.index + 1}"
    Index = count.index + 1
  })
}

