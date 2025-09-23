# ecs.tf
# ECS infrastructure for Java Tomcat application
# Production configuration with optimized memory allocation

# ECS Cluster with container insights
resource "aws_ecs_cluster" "main" {
  count = var.enabled ? 1 : 0
  name  = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}-cluster"
    Description = "ECS cluster for memory optimization demo - all ${var.number_of_containers} containers will restart on memory change"
  })
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_execution_role" {
  count = var.enabled ? 1 : 0
  name  = "${local.name_prefix}-ecs-execution-role"

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

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  count      = var.enabled ? 1 : 0
  role       = aws_iam_role.ecs_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role (for the application itself)
resource "aws_iam_role" "ecs_task_role" {
  count = var.enabled ? 1 : 0
  name  = "${local.name_prefix}-ecs-task-role"

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

  tags = local.common_tags
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  count             = var.enabled ? 1 : 0
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = 1  # Reduced from 7 days for cost optimization

  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}-logs"
    Description = "Logs will show OOM kills when memory is reduced to 1024MB"
  })
}

# ECS Task Definition - THE TRAP IS HERE!
resource "aws_ecs_task_definition" "app" {
  count                    = var.enabled ? 1 : 0
  family                   = "${local.name_prefix}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu_units
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role[0].arn
  task_role_arn           = aws_iam_role.ecs_task_role[0].arn

  container_definitions = jsonencode([
    {
      name  = "tomcat-app"
      image = "tomcat:9-jre11"
      
      # THE CRITICAL CONFIGURATION - Java heap size that will cause OOM!
      environment = [
        {
          name  = "JAVA_OPTS"
          # THIS IS THE TRAP! JVM configured for 1536MB heap + 256MB overhead = 1792MB total
          # When container_memory changes to 1024MB, this will cause immediate OOM kills
          value = "-Xmx${var.java_heap_size_mb}m -Xms${var.java_heap_size_mb}m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
        },
        {
          name  = "CATALINA_OPTS"
          value = "-Djava.security.egd=file:/dev/./urandom"
        }
      ]

      # MISLEADING METRIC! This shows only 800MB average, hiding the real requirement
      memoryReservation = 800
      
      # Health check with enough time for JVM startup
      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:${var.application_port}/ || exit 1"
        ]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = var.health_check_grace_period
      }

      portMappings = [
        {
          containerPort = var.application_port
          hostPort      = var.application_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app[0].name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      essential = true
    }
  ])

  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}-task"
    Description = "Task definition showing Java heap trap - needs ${var.java_heap_size_mb + 256}MB but will get ${var.container_memory}MB"
    
    # Critical warning tags
    "warning:java-heap-size"     = "${var.java_heap_size_mb}MB"
    "warning:memory-overhead"    = "256MB (metaspace + OS)"
    "warning:total-required"     = "${var.java_heap_size_mb + 256}MB"
    "warning:container-memory"   = "${var.container_memory}MB"
    "warning:will-oom-on-1024"  = "true"
  })
}

# ECS Service - All containers will restart when memory changes
resource "aws_ecs_service" "app" {
  count           = var.enabled ? 1 : 0
  name            = "${local.name_prefix}-service"
  cluster         = aws_ecs_cluster.main[0].id
  task_definition = aws_ecs_task_definition.app[0].arn
  desired_count   = var.number_of_containers
  launch_type     = "FARGATE"

  # Rolling deployment configuration - ALL containers will restart!
  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = false
    rollback = false
  }

  network_configuration {
    subnets          = local.subnet_ids
    security_groups  = [aws_security_group.ecs_tasks[0].id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app[0].arn
    container_name   = "tomcat-app"
    container_port   = var.application_port
  }

  depends_on = [
    aws_lb_listener.app
  ]

  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}-service"
    Description = "ECS service with ${var.number_of_containers} containers - ALL will restart when memory changes"
    
    # Impact warning tags
    "impact:containers-affected" = tostring(var.number_of_containers)
    "impact:deployment-type"     = "rolling"
    "impact:black-friday-risk"   = "all containers restart during peak season"
  })
}

# Data source for current AWS region
data "aws_region" "current" {}