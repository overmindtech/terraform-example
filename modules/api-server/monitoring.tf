# monitoring.tf
# CloudWatch Alarms and SNS Topic

resource "aws_sns_topic" "alerts" {
  count = var.enabled ? 1 : 0

  name = "${local.name_prefix}-alerts"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alerts"
  })
}

resource "aws_sns_topic_policy" "alerts" {
  count = var.enabled ? 1 : 0

  arn = aws_sns_topic.alerts[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.alerts[0].arn
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = var.enabled ? 1 : 0

  alarm_name          = "${local.name_prefix}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU utilization exceeds 80%"

  dimensions = {
    InstanceId = aws_instance.api_server[0].id
  }

  alarm_actions = [aws_sns_topic.alerts[0].arn]
  ok_actions    = [aws_sns_topic.alerts[0].arn]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cpu-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "cpu_credits" {
  count = var.enabled && local.is_burstable ? 1 : 0

  alarm_name          = "${local.name_prefix}-cpu-credits-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUCreditBalance"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 50
  alarm_description   = "CPU credit balance is low"

  dimensions = {
    InstanceId = aws_instance.api_server[0].id
  }

  alarm_actions = [aws_sns_topic.alerts[0].arn]
  ok_actions    = [aws_sns_topic.alerts[0].arn]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-credits-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  count = var.enabled ? 1 : 0

  alarm_name          = "${local.name_prefix}-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Load balancer has unhealthy targets"

  dimensions = {
    LoadBalancer = aws_lb.api[0].arn_suffix
    TargetGroup  = aws_lb_target_group.api[0].arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts[0].arn]
  ok_actions    = [aws_sns_topic.alerts[0].arn]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-health-alarm"
  })
}

