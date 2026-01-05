# Scale Testing Infrastructure for Overmind

> **ENG-2073 / PRD-825** - AWS and GCP infrastructure for testing Overmind's blast radius and risk analysis capabilities at scale.

## Overview

This Terraform configuration creates 100-10,000 cloud resources across AWS and GCP for validating Overmind's performance at enterprise scale. Resources are designed to have realistic relationships for blast radius testing while remaining cost-optimized.

## Architecture

```
terraform-example/scale-test
    ↓ terraform apply
Scale test AWS account + GCP project (100-10,000 resources)
    ↓ discovered by
Prod Overmind sources (connected to scale test accounts)
    ↓ analyzed by
Prod Overmind (blast radius, risk analysis at scale)
    ↓ metrics captured
Benchmark framework (PRD-826)
```

### Multi-Region Distribution

| AWS Regions | GCP Regions |
|-------------|-------------|
| us-east-1 | us-central1 |
| us-west-2 | us-west1 |
| eu-west-1 | europe-west1 |
| ap-southeast-1 | asia-southeast1 |

## Quick Start

### Prerequisites

- Terraform >= 1.12.0
- AWS credentials with permissions to create resources in the scale-test account
- GCP credentials with permissions for the `ovm-scale-test` project
- S3 bucket `overmind-scale-test-tfstate` for state storage (or use local backend)

### Usage

```bash
cd scale-test

# Initialize (first time only)
terraform init

# Plan with different scale levels
terraform plan -var="scale_multiplier=1"    # ~100 resources
terraform plan -var="scale_multiplier=10"   # ~1,000 resources
terraform plan -var="scale_multiplier=100"  # ~10,000 resources

# Apply
terraform apply -var="scale_multiplier=1"

# Destroy
terraform destroy -var="scale_multiplier=1"
```

### Using Local Backend (Development)

To use a local backend instead of S3, edit `backend.tf`:

```hcl
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

## Scale Multiplier

The `scale_multiplier` variable controls all resource counts:

| Multiplier | Total Resources | Use Case |
|------------|----------------|----------|
| 1 | ~100 | Development, quick testing |
| 10 | ~1,000 | Medium scale validation |
| 100 | ~10,000 | Full enterprise scale test |

### Base Resource Counts (×1 Multiplier)

| Resource Type | AWS | GCP | Total |
|---------------|-----|-----|-------|
| SSM Parameters / Secrets | 25 | 25 | 50 |
| SQS Queues / Pub/Sub Subs | 15 | 15 | 30 |
| SNS Topics / Pub/Sub Topics | 10 | 10 | 20 |
| CloudWatch Log Groups | 10 | - | 10 |
| IAM Roles / Service Accounts | 10 | 10 | 20 |
| Security Groups / Firewall Rules | 5 | 5 | 10 |
| Lambda / Cloud Functions | 5 | 5 | 10 |
| S3 / GCS Buckets | 1 | 1 | 2 |
| EC2 / GCE Instances | 2 | 2 | 4 |
| VPCs (with subnets, routes) | 4 | 4 | 8 |

## Cost Control

Resources are designed to minimize costs while still being discoverable:

- **EC2/GCE instances**: Created in stopped state
- **EBS/Persistent disks**: Minimum viable size (4GB gp3)
- **No NAT Gateways**: Public subnets only
- **No Load Balancers**: Direct instance access
- **Empty S3/GCS buckets**: No data storage costs
- **Lambda/Cloud Functions**: Minimal memory, no invocations
- **No log data**: Empty log groups

### Estimated Monthly Costs

| Multiplier | Low Estimate | High Estimate |
|------------|--------------|---------------|
| 1 | $5-10 | $15-20 |
| 10 | $30-50 | $80-100 |
| 100 | $80-120 | $150-200 |

*Costs are primarily from stopped EC2/GCE instances and EBS/disk storage.*

## Relationship Density

Resources reference each other to create realistic blast radius graphs:

```hcl
# Lambda uses shared IAM roles
resource "aws_lambda_function" "test" {
  count = local.count.lambda_functions
  role  = aws_iam_role.shared[count.index % local.count.iam_roles].arn
}

# EC2 instances share security groups
resource "aws_instance" "test" {
  count                  = local.count.ec2_instances
  vpc_security_group_ids = [aws_security_group.shared[count.index % local.count.security_groups].id]
}

# SQS queues reference SNS topics
resource "aws_sqs_queue_policy" "test" {
  count     = local.count.sqs_queues
  queue_url = aws_sqs_queue.test[count.index].id
  # Policy allows SNS topic to send messages
}
```

## Directory Structure

```
scale-test/
├── main.tf           # Module composition and locals
├── variables.tf      # scale_multiplier and configuration
├── outputs.tf        # Resource counts and cost estimates
├── providers.tf      # Multi-region AWS/GCP providers
├── backend.tf        # State storage configuration
├── versions.tf       # Provider version requirements
├── README.md         # This file
│
└── modules/
    ├── aws/
    │   ├── network/      # VPCs, subnets, security groups
    │   ├── compute/      # EC2, Lambda
    │   ├── messaging/    # SQS, SNS
    │   ├── storage/      # S3, SSM Parameters
    │   └── iam/          # Roles, policies
    │
    └── gcp/
        ├── network/      # VPC, subnets, firewall rules
        ├── compute/      # GCE, Cloud Functions
        ├── messaging/    # Pub/Sub
        ├── storage/      # GCS, Secret Manager
        └── iam/          # Service accounts
```

## GitHub Actions

Use the workflow at `.github/workflows/scale-test.yml` for CI/CD:

```bash
# Via GitHub UI
# 1. Go to Actions → Scale Test Infrastructure
# 2. Click "Run workflow"
# 3. Select action (plan/apply/destroy) and scale_multiplier
# 4. For destroy, enter confirmation text

# Results are submitted to prod Overmind for analysis
```

## Integration with Prod Overmind

### Configure Sources

1. Add scale-test AWS account to prod AWS source configuration
2. Add scale-test GCP project to prod GCP source configuration
3. Verify resources appear in Overmind inventory

### Validate Blast Radius

1. Create a change in the scale-test infrastructure
2. Submit plan to Overmind via CLI or workflow
3. Review blast radius and affected resources
4. Measure analysis performance at different scale levels

## Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `scale_multiplier` | number | 1 | Resource count multiplier (1, 10, or 100) |
| `gcp_project_id` | string | "ovm-scale-test" | GCP project for resources |
| `enable_ec2_instances` | bool | true | Create EC2 instances |
| `enable_gce_instances` | bool | true | Create GCE instances |
| `enable_lambda_functions` | bool | true | Create Lambda functions |
| `enable_cloud_functions` | bool | true | Create Cloud Functions |
| `ec2_instance_type` | string | "t3.micro" | EC2 instance type |
| `gce_machine_type` | string | "e2-micro" | GCE machine type |

## Outputs

```bash
# After apply, view outputs
terraform output

# Key outputs:
# - scale_summary: Multiplier and total resource count
# - resource_counts: Breakdown by resource type
# - estimated_monthly_cost: Cost estimates
# - region_distribution: Resources per region
# - validation_info: Next steps for Overmind integration
```

## Troubleshooting

### Service Limits

If you hit AWS/GCP service limits at high multipliers:
1. Request limit increases for the scale-test account
2. Distribute resources across more regions
3. Reduce specific resource types via `enable_*` variables

### State Lock Errors

```bash
# If state is locked from a failed run
terraform force-unlock LOCK_ID
```

### Cost Overruns

```bash
# Quickly destroy all resources
terraform destroy -var="scale_multiplier=100" -auto-approve

# Disable expensive resources first
terraform apply -var="scale_multiplier=100" \
  -var="enable_ec2_instances=false" \
  -var="enable_gce_instances=false"
```

## Related

- [ENG-2073](https://linear.app/overmind/issue/ENG-2073) - Scale Testing Infrastructure
- [PRD-825](https://linear.app/overmind/issue/PRD-825) - Scale Testing Requirements
- [PRD-826](https://linear.app/overmind/issue/PRD-826) - Benchmark Framework

