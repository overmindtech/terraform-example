# outputs.tf
# Following guide.md requirements for memory optimization demo
# Module outputs showing demo status and instructions

output "alb_url" {
  description = "URL to access the application"
  value       = var.enabled ? "http://${aws_lb.app[0].dns_name}" : null
}

output "demo_status" {
  description = "Object showing current vs required memory, cost calculations, and risk assessment"
  value = var.enabled ? {
    # Memory analysis
    current_memory_mb    = var.container_memory
    required_memory_mb   = local.required_memory_mb
    java_heap_size_mb   = var.java_heap_size_mb
    memory_overhead_mb  = 256
    will_it_work        = local.will_it_work
    
    # Cost calculations
    current_cost_month   = "$${local.current_cost_month}"
    optimized_cost_month = "$${local.optimized_cost_month}"
    monthly_savings      = "$${local.monthly_savings}"
    annual_savings       = "$${local.monthly_savings * 12}"
    
    # Risk assessment
    risk_level           = local.will_it_work ? "LOW" : "CRITICAL"
    containers_affected  = var.number_of_containers
    days_until_black_friday = var.days_until_black_friday
    deregistration_delay = "${var.deregistration_delay} seconds"
    rollback_capability  = var.deregistration_delay > 30 ? "possible" : "insufficient"
    
    # Business impact
    business_context = {
      timing               = "Friday afternoon change"
      black_friday_risk    = "${var.days_until_black_friday} days until peak traffic"
      last_memory_change   = "${var.days_since_last_memory_change} days ago"
      traffic_multiplier   = "10x expected on Black Friday"
      change_window        = "unsafe - too close to peak season"
    }
    
    # Technical details
    technical_analysis = {
      jvm_configuration    = "JAVA_OPTS=-Xmx${var.java_heap_size_mb}m -Xms${var.java_heap_size_mb}m"
      container_limit      = "${var.container_memory}MB"
      memory_gap           = "${var.container_memory - local.required_memory_mb}MB"
      oom_prediction       = var.container_memory < local.required_memory_mb ? "IMMEDIATE" : "none"
      gc_behavior          = var.container_memory < local.required_memory_mb ? "thrashing before crash" : "normal"
    }
  } : null
}

output "instructions" {
  description = "How to break and fix the demo"
  value = var.enabled ? {
    demo_flow = {
      step_1 = "Current state: Deploy with container_memory = ${var.container_memory}MB (SAFE)"
      step_2 = "Create branch: git checkout -b memory-optimization"
      step_3 = "Change: Set container_memory = 1024 in variables or module call"
      step_4 = "Plan: terraform plan (shows 2 resources changing)"
      step_5 = "Reality: All ${var.number_of_containers} containers will crash immediately"
      step_6 = "Overmind: Would reveal 47+ resources affected by this change"
      step_7 = "Fix: Change container_memory back to 2048MB or higher"
      step_8 = "Cleanup: terraform destroy when done"
    }
    
    breaking_change = {
      what_to_change = "container_memory variable from ${var.container_memory} to 1024"
      where_to_change = [
        "variables.tf default value",
        "module call parameter",
        "terraform.tfvars file"
      ]
      terraform_command = "terraform apply -var='container_memory=1024'"
    }
    
    explanation = {
      why_it_breaks = [
        "Java heap configured for ${var.java_heap_size_mb}MB (-Xmx${var.java_heap_size_mb}m)",
        "JVM needs ${var.java_heap_size_mb}MB heap + 256MB overhead = ${local.required_memory_mb}MB total",
        "Container memory limit of 1024MB < ${local.required_memory_mb}MB required",
        "Result: Immediate OutOfMemoryError on container startup"
      ]
      
      why_monitoring_misleads = [
        "CloudWatch shows memoryReservation = 800MB (misleading!)",
        "Average memory usage appears low due to GC cycles",
        "P99 memory usage during GC spikes to ~1.8GB",
        "Container insights don't show JVM heap requirements"
      ]
      
      why_timing_matters = [
        "Change scheduled ${var.days_until_black_friday} days before Black Friday",
        "Black Friday brings 10x normal traffic load",
        "All ${var.number_of_containers} containers restart simultaneously",
        "${var.deregistration_delay}s deregistration = no rollback time",
        "Last memory change was ${var.days_since_last_memory_change} days ago (stale knowledge)"
      ]
    }
    
    overmind_insights = {
      visible_changes = "2 resources (task definition, service)"
      hidden_impacts = [
        "ALB target group health checks",
        "CloudWatch alarms triggering",
        "Auto Scaling reactions",
        "Service discovery updates",
        "Log stream disruptions",
        "Connected microservices affected",
        "Database connection pooling impact"
      ]
      total_affected_resources = "47+ resources in typical production environment"
    }
  } : null
}

output "cluster_name" {
  description = "ECS cluster name for monitoring"
  value       = var.enabled ? aws_ecs_cluster.main[0].name : null
}

output "service_name" {
  description = "ECS service name for monitoring"
  value       = var.enabled ? aws_ecs_service.app[0].name : null
}

output "log_group_name" {
  description = "CloudWatch log group name to check for OOM errors"
  value       = var.enabled ? aws_cloudwatch_log_group.app[0].name : null
}

output "cost_analysis" {
  description = "Detailed cost breakdown showing the financial motivation for the risky change"
  value = var.enabled ? {
    current_configuration = {
      memory_per_container = "${var.container_memory}MB"
      number_of_containers = var.number_of_containers
      memory_cost_per_gb   = "$${local.cost_per_gb_month}/month"
      total_monthly_cost   = "$${local.current_cost_month}/month"
      annual_cost          = "$${local.current_cost_month * 12}/year"
    }
    
    proposed_optimization = {
      memory_per_container = "1024MB"
      number_of_containers = var.number_of_containers
      memory_cost_per_gb   = "$${local.cost_per_gb_month}/month"
      total_monthly_cost   = "$${local.optimized_cost_month}/month"
      annual_cost          = "$${local.optimized_cost_month * 12}/year"
    }
    
    savings_projection = {
      monthly_savings = "$${local.monthly_savings}"
      annual_savings  = "$${local.monthly_savings * 12}"
      percentage_saved = "${floor((local.monthly_savings / local.current_cost_month) * 100)}%"
    }
    
    business_pressure = {
      motivation = "Significant cost savings opportunity identified"
      timing_pressure = "CFO wants cost reductions before Black Friday"
      appears_safe = "Monitoring shows only 800MB average usage"
      hidden_risk = "JVM actually needs ${local.required_memory_mb}MB total"
    }
  } : null
}

output "resource_tags" {
  description = "Common tags applied to all resources for tracking demo context"
  value       = var.enabled ? local.common_tags : null
}