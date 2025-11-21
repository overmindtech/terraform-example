# Route53 DNS record for blackhole scenario testing
# This simulates DNS endpoint going dark by pointing to ALB with empty target group
# No failover, no health checks - mimics AWS DNS outage scenario

resource "aws_route53_record" "blackhole" {
  count   = var.enable_memory_optimization_demo ? 1 : 0
  zone_id = data.aws_route53_zone.demo.zone_id
  name    = "blackhole-${var.example_env}.${data.aws_route53_zone.demo.name}"
  type    = "A"

  alias {
    name                   = module.memory_optimization.alb_dns_name
    zone_id                = module.memory_optimization.alb_zone_id
    evaluate_target_health = false
  }

  # TTL is ignored for alias records but included for documentation
  # High TTL (300s = 5 minutes) indicates no failover capability
  # No health check evaluation - mimics DNS endpoint going dark
}

