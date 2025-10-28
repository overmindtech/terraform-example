# monitoring.tf
# CloudWatch monitoring and alerting for Java application performance
# Production-grade monitoring for ECS service health and resource utilization

# SNS Topic for alarm notifications
resource "aws_sns_topic" "alerts" {
  count = var.enabled ? 1 : 0
  name  = "${local.name_prefix}-alerts"

  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}-alerts"
    Description = "SNS topic for memory optimization demo alerts - will fire when containers OOM"
  })
}

# CloudWatch Alarm for high memory utilization
resource "aws_cloudwatch_metric_alarm" "high_memory_utilization" {
  count               = var.enabled ? 1 : 0
  alarm_name          = "${local.name_prefix}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3" # Changed from "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"  # 5 minutes for cost optimization
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS memory utilization - WILL FIRE when containers run out of memory"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]
  ok_actions          = [aws_sns_topic.alerts[0].arn]

  dimensions = {
    ServiceName = aws_ecs_service.app[0].name
    ClusterName = aws_ecs_cluster.main[0].name
  }

  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}-memory-alarm"
    Description = "Memory utilization alarm for Java application"
    
    # Alarm metadata
    AlarmTrigger       = "memory-over-80-percent"
    JavaHeapMB         = tostring(var.java_heap_size_mb)
    ContainerMemoryMB  = tostring(var.container_memory)
    WillFireAfterChange = tostring(var.container_memory < var.java_heap_size_mb + 256)
  })
}

# CloudWatch Alarm for low task count (containers crashing)
resource "aws_cloudwatch_metric_alarm" "low_task_count" {
  count               = var.enabled ? 1 : 0
  alarm_name          = "${local.name_prefix}-low-task-count"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.number_of_containers * 0.8  # 80% of expected tasks
  alarm_description   = "This metric monitors ECS running task count - WILL FIRE when containers crash due to OOM"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]
  ok_actions          = [aws_sns_topic.alerts[0].arn]

  dimensions = {
    ServiceName = aws_ecs_service.app[0].name
    ClusterName = aws_ecs_cluster.main[0].name
  }

  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}-task-count-alarm"
    Description = "Task count alarm for container health monitoring"
    
    # Alarm metadata
    ExpectedTasks      = tostring(var.number_of_containers)
    ThresholdTasks     = tostring(var.number_of_containers * 0.8)
    CrashCause         = "OOM-when-memory-reduced"
    BusinessImpact     = "service-degradation"
  })
}

# CloudWatch Alarm for high CPU (JVM struggling with limited memory)
resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  count               = var.enabled ? 1 : 0
  alarm_name          = "${local.name_prefix}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS CPU utilization - will spike when JVM struggles with insufficient memory"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]

  dimensions = {
    ServiceName = aws_ecs_service.app[0].name
    ClusterName = aws_ecs_cluster.main[0].name
  }

  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}-cpu-alarm"
    Description = "CPU utilization alarm for Java application performance"
    
    # Technical metadata
    GCPressure         = "high-when-heap-approaches-limit"
    JVMBehavior        = "CPU-spikes-before-OOM"
    MemoryThrashing    = "frequent-GC-when-constrained"
  })
}

# CloudWatch Alarm for ALB target health
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  count               = var.enabled ? 1 : 0
  alarm_name          = "${local.name_prefix}-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "This metric monitors ALB unhealthy targets - will fire when containers become unresponsive"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]

  dimensions = {
    TargetGroup  = aws_lb_target_group.app[0].arn_suffix
    LoadBalancer = aws_lb.app[0].arn_suffix
  }

  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}-unhealthy-targets-alarm"
    Description = "ALB target health monitoring for application availability"
    
    # Impact metadata
    UserExperience     = "failed-requests-during-crashes"
    DeregistrationTime = "${var.deregistration_delay}s"
    RollbackCapability = "insufficient"
    BusinessRisk       = "outage-before-peak-season"
  })
}

# CloudWatch Log Insights query for OOM events (for troubleshooting)
resource "aws_cloudwatch_query_definition" "oom_events" {
  count = var.enabled ? 1 : 0
  name  = "${local.name_prefix}-oom-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.app[0].name
  ]

  query_string = <<-EOT
    fields @timestamp, @message
    | filter @message like /OutOfMemoryError/
    | sort @timestamp desc
    | limit 100
  EOT
}

# Custom metric for demo purposes - memory pressure indicator
resource "aws_cloudwatch_log_metric_filter" "memory_pressure" {
  count          = var.enabled ? 1 : 0
  name           = "${local.name_prefix}-memory-pressure"
  log_group_name = aws_cloudwatch_log_group.app[0].name
  pattern        = "[timestamp, requestId, level=\"ERROR\", message=\"*OutOfMemoryError*\"]"

  metric_transformation {
    name      = "JavaOOMErrors"
    namespace = "MemoryOptimization/Demo"
    value     = "1"
  }
}