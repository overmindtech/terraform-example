# output "terraform_deploy_role" {
#   value = aws_iam_role.deploy_role.arn
# }

# GCP Workload Identity Federation outputs (needed for CI platform configuration)
output "gcp_workload_identity_provider" {
  description = "Full resource name of the GitHub Actions WIF provider (for google-github-actions/auth)"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "gcp_service_account_email" {
  description = "Email of the GCP deploy service account"
  value       = google_service_account.deploy.email
}

# Paste the value of this output when creating a "GCP OIDC" deployment
# credential in env0 (Organization Settings -> Credentials -> New -> GCP OIDC).
# It mirrors the JSON that GCP's "Configure your application" wizard would
# produce, but built from the Terraform-managed pool/provider/SA above so it
# stays in sync.
output "env0_gcp_oidc_credential_json" {
  description = "JSON to paste into the env0 'GCP OIDC' deployment credential."
  value = var.example_env == "terraform-example" ? jsonencode({
    type                              = "external_account"
    audience                          = "//iam.googleapis.com/${google_iam_workload_identity_pool_provider.env0[0].name}"
    subject_token_type                = "urn:ietf:params:oauth:token-type:jwt"
    token_url                         = "https://sts.googleapis.com/v1/token"
    service_account_impersonation_url = "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/${google_service_account.deploy.email}:generateAccessToken"
    credential_source = {
      file = "env0-oidc-token.txt"
      format = {
        type = "text"
      }
    }
  }) : null
}

# API Server outputs
output "api_server_url" {
  description = "URL to access the API server"
  value       = module.api_server.alb_url
}

output "api_server_instance_id" {
  description = "Instance ID for start/stop commands"
  value       = module.api_server.instance_id
}

# Shared Security Group outputs
output "shared_sg_security_group_id" {
  description = "ID of the internet-access security group (for manual instance creation)"
  value       = module.shared_security_group.security_group_id
}

output "shared_sg_api_server_id" {
  description = "Instance ID of the shared SG demo API server"
  value       = module.shared_security_group.api_server_instance_id
}

output "shared_sg_manual_instance_command" {
  description = "CLI command to create the manual data-processor instance"
  value       = module.shared_security_group.manual_instance_command
}

# ------------------------------------------------------------------------------
# Signals demo (monitoring VPC + NLB health proof)
# ------------------------------------------------------------------------------

output "signals_monitoring_vpc_id" {
  description = "ID of the peered monitoring/shared-services VPC (signals demo)"
  value       = var.enable_api_access ? module.api_access[0].monitoring_vpc_id : null
}

output "signals_vpc_peering_connection_id" {
  description = "VPC peering connection ID between baseline and monitoring VPC (signals demo)"
  value       = var.enable_api_access ? module.api_access[0].vpc_peering_connection_id : null
}

output "signals_monitoring_nlb_arn" {
  description = "ARN of the internal NLB in the monitoring VPC (signals demo)"
  value       = var.enable_api_access ? module.api_access[0].monitoring_nlb_arn : null
}

output "signals_monitoring_nlb_dns_name" {
  description = "DNS name of the internal NLB in the monitoring VPC (signals demo)"
  value       = var.enable_api_access ? module.api_access[0].monitoring_nlb_dns_name : null
}

output "signals_monitoring_target_group_arn" {
  description = "Target group ARN used to health-check the API instance from the monitoring VPC (signals demo)"
  value       = var.enable_api_access ? module.api_access[0].monitoring_target_group_arn : null
}

# ------------------------------------------------------------------------------
# GCP Platform Demo (wrapper module pattern)
# ------------------------------------------------------------------------------

output "gcp_platform_network" {
  description = "Self-link of the GCP platform VPC network"
  value       = google_compute_network.platform.self_link
}

output "gcp_payments_instance_name" {
  description = "Name of the payments API GCE instance"
  value       = module.payments_service.instance_name
}

output "gcp_payments_instance_ip" {
  description = "Internal IP of the payments API instance"
  value       = module.payments_service.instance_internal_ip
}

output "gcp_payments_firewall" {
  description = "Name of the payments ingress firewall rule"
  value       = module.payments_service.firewall_rule_name
}

output "gcp_inventory_instance_name" {
  description = "Name of the inventory API GCE instance"
  value       = module.inventory_service.instance_name
}

output "gcp_inventory_instance_ip" {
  description = "Internal IP of the inventory API instance"
  value       = module.inventory_service.instance_internal_ip
}

output "gcp_inventory_firewall" {
  description = "Name of the inventory ingress firewall rule"
  value       = module.inventory_service.firewall_rule_name
}
