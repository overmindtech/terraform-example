# output "terraform_deploy_role" {
#   value = aws_iam_role.deploy_role.arn
# }

output "demo_event_bus" {
  description = "EventBridge bus name handling asset lifecycle events"
  value       = length(module.serverless_demo) > 0 ? module.serverless_demo[0].event_bus_name : null
}
