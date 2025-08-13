locals {
  domain_name = "${var.example_env}.modules.tf"
}

#######################
# Simplified Loom Example #
#######################

# Simple S3 buckets
resource "aws_s3_bucket" "main_bucket" {
  bucket_prefix = "main-${var.example_env}-${random_pet.this.id}"
  force_destroy = true

  tags = {
    Name        = "Main bucket"
    Environment = var.example_env
    Purpose     = "Main storage"
  }
}

resource "aws_s3_bucket" "data_lake" {
  bucket_prefix = "data-lake-${var.example_env}-${random_pet.this.id}"
  force_destroy = true

  tags = {
    Name        = "Data Lake"
    Environment = var.example_env
    Purpose     = "Analytics and data processing"
  }
}

resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Random pets for naming
resource "random_pet" "this" {
  length = 2
}

resource "random_pet" "second" {
  length = 2
}

# Simple ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "simple-${var.example_env}"

  tags = {
    Name        = "Simple ECS Cluster"
    Environment = var.example_env
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "simple-${var.example_env}"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets

  tags = {
    Environment = var.example_env
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Hello from ALB"
      status_code  = "200"
    }
  }
}

# Simple SQS Queue
resource "aws_sqs_queue" "processing_queue" {
  name = "processing-${var.example_env}"

  tags = {
    Environment = var.example_env
    Purpose     = "Message processing"
  }
}

# Simple SQS Dead Letter Queue
resource "aws_sqs_queue" "dlq" {
  name = "dlq-${var.example_env}"

  tags = {
    Environment = var.example_env
    Purpose     = "Dead letter queue"
  }
}

# Simple Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "lambda-role-${var.example_env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

data "archive_file" "simple_lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/tmp/simple_lambda.zip"

  source {
    content = <<EOF
import json

def lambda_handler(event, context):
    print("Processing event:", event)
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
EOF
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "processor" {
  function_name    = "simple-processor-${var.example_env}"
  filename         = data.archive_file.simple_lambda_zip.output_path
  source_code_hash = data.archive_file.simple_lambda_zip.output_base64sha256
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  timeout          = 30

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.data_lake.bucket
      QUEUE_URL   = aws_sqs_queue.processing_queue.url
    }
  }

  tags = {
    Environment = var.example_env
    Purpose     = "Simple processing function"
  }
}

# Simple RDS Database
resource "aws_db_subnet_group" "main" {
  name       = "main-${var.example_env}"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name        = "Main DB subnet group"
    Environment = var.example_env
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "rds-${var.example_env}-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "RDS security group"
    Environment = var.example_env
  }
}

resource "aws_db_instance" "main" {
  identifier             = "simple-db-${var.example_env}"
  engine                 = "postgres"
  engine_version         = "15.8"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_encrypted      = true
  db_name                = "simpledb"
  username               = "postgres"
  password               = "changeme123!"
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true

  tags = {
    Name        = "Simple Database"
    Environment = var.example_env
  }
}

# Simple ECS Task Definition
resource "aws_ecs_task_definition" "web_app" {
  family                   = "web-app-${var.example_env}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "web-app"
      image     = "nginx:alpine"
      cpu       = 256
      memory    = 512
      essential = true
      environment = [
        {
          name  = "DATABASE_URL"
          value = "postgresql://postgres:changeme123!@${aws_db_instance.main.endpoint}:5432/simpledb"
        }
      ]
      portMappings = [
        {
          containerPort = 80
        }
      ]
    }
  ])
}

# ECS Execution Role
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-${var.example_env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Service
resource "aws_ecs_service" "web_app" {
  name            = "web-app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web_app.arn
  desired_count   = 1

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [module.vpc.default_security_group_id]
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ecs/simple-${var.example_env}"
  retention_in_days = 7

  tags = {
    Environment = var.example_env
    Application = "simple-web-app"
  }
}
