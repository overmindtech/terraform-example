# Scale Testing Infrastructure for Overmind

AWS infrastructure for testing Overmind's blast radius and risk analysis at scale.

## Overview

Creates 175-8,700 AWS resources across 4 regions with realistic relationship density for blast radius testing. Resources are cost-optimized (stopped EC2, empty S3, no invocations).

## Quick Start

### Via GitHub Actions (Recommended)

1. Go to **Actions** > **Scale Test Infrastructure**
2. Click **Run workflow**
3. Select options:
   - **Action**: plan, apply, or destroy
   - **Scale**: 1, 5, 10, 25, or 50
   - **Scenario**: none (baseline) or a test scenario

### Local Development

```bash
cd scale-test
terraform init
terraform plan -var="scale_multiplier=1"
terraform apply -var="scale_multiplier=1"
```

## Scale Multiplier

| Multiplier | AWS Resources | Est. Monthly Cost |
|------------|---------------|-------------------|
| 1 | ~175 | $10-20 |
| 5 | ~870 | $30-50 |
| 10 | ~1,740 | $50-80 |
| 25 | ~4,350 | $120-150 |
| 50 | ~8,700 | $200-300 |

## Test Scenarios

Scenarios modify infrastructure to trigger specific risks. See [SCENARIOS.md](SCENARIOS.md) for details.

| Scenario | Description | Blast Radius |
|----------|-------------|--------------|
| `shared_sg_open` | Opens SSH on shared security group | High |
| `vpc_peering_change` | Modifies VPC peering DNS settings | Very High |
| `sg_open_ssh` | Opens SSH on individual SGs | Medium |
| `ec2_downgrade` | Downgrades EC2 instance type | Low |
| `lambda_timeout` | Reduces Lambda timeout | Low |

### Testing Workflow

```bash
# 1. Apply baseline infrastructure
terraform apply -var="scale_multiplier=10" -var="scenario=none"

# 2. Plan with scenario (submits to Overmind)
terraform plan -var="scale_multiplier=10" -var="scenario=shared_sg_open"

# 3. Destroy when done
terraform destroy -var="scale_multiplier=10"
```

## Quality Evaluation

The GitHub Actions workflow includes automated quality evaluation that validates expected risks are detected for each scenario.

### How It Works

1. **Plan submitted to Overmind** - The terraform plan is analyzed by Overmind
2. **Results fetched as JSON** - `overmind changes get-change --format json`
3. **Assertions run** - Scenario-specific checks validate expected risks
4. **Results saved as artifacts** - `change-results.json` and `tfplan.json`

### Expected Results by Scenario

| Scenario | Expected Risk | Severity | Assertion |
|----------|---------------|----------|-----------|
| `shared_sg_open` | SSH open to 0.0.0.0/0 | high/critical | Fails if no high-severity risk |
| `lambda_timeout` | Timeout too short | medium | Fails if no timeout risk |
| `vpc_peering_change` | DNS resolution change | varies | Does not fail (ambiguous) |
| `central_sns_change` | SNS policy change | high | Fails if no risk found |
| `combined_*` | Multiple risks | high/critical | Fails if no high-severity risk |
| `shared_firewall_open` | GCP firewall open | high/critical | Fails if no high-severity risk |
| `function_timeout` | Cloud Function timeout | medium | Fails if no risk found |

### Viewing Results

After a workflow run:

1. Go to **Actions** → Select the workflow run
2. View the **Summary** tab for risk detection results
3. Download **Artifacts** for full JSON results

### GitHub Step Summary Output

The workflow generates a summary like:

```
## Terraform Plan Summary
- Scale Multiplier: 10
- Scenario: shared_sg_open
- Action: plan

## Change Analysis Results
- Total Risks: 3
- High/Critical Risks: 2
- Medium Risks: 1

### Detected Risks
- **[critical]** Security Group Opens SSH to Internet
- **[high]** Shared Resource Modification Affects Multiple Instances
- **[medium]** Configuration Change May Impact Availability

### Scenario Validation: `shared_sg_open`
✅ **PASSED** - Expected risks were detected
```

## Architecture

### Regions

- us-east-1
- us-west-2
- eu-west-1
- ap-southeast-1

### High Fan-Out Resources

These shared resources create large blast radii:

- **Shared Security Group**: Attached to all EC2 instances in each region
- **Shared IAM Role**: Used by all Lambda functions in each region
- **VPC Peering Mesh**: Full mesh connecting all 4 VPCs

### Resource Types per Region

| Resource | Count at 1x | Relationship |
|----------|-------------|--------------|
| VPC | 1 | Contains all resources |
| Subnets | 6 | 3 public, 3 private |
| Security Groups | 2 | Shared + high-fanout |
| EC2 Instances | 1 | Stopped, attached to shared SG |
| Lambda Functions | 2 | Using shared IAM role |
| SQS Queues | 5 | Subscribed to SNS |
| SNS Topics | 5 | Cross-references |
| S3 Buckets | 1 | Empty |
| SSM Parameters | 5 | Config storage |
| IAM Roles | 3 | Shared by resources |

## Cost Control

- EC2 instances created in stopped state
- EBS volumes at minimum 30GB (required by AMI)
- No NAT Gateways or Load Balancers
- Empty S3 buckets
- Lambda functions never invoked
- VPC peering has no data transfer costs

## Backend

State is stored in S3 with DynamoDB locking:

```
Bucket: overmind-scale-test-tfstate
Key: scale-test/terraform.tfstate
Lock Table: overmind-scale-test-tfstate-lock
```

## Directory Structure

```
scale-test/
├── main.tf                   # Module instantiation
├── variables.tf              # Input variables
├── outputs.tf                # Resource summaries
├── providers.tf              # Multi-region providers
├── backend.tf                # S3 state config
├── vpc_peering.tf            # Cross-region peering mesh
├── scenario_*.tf             # Test scenario definitions
├── SCENARIOS.md              # Scenario documentation
└── modules/
    └── aws/                  # AWS resources
        ├── main.tf
        ├── network.tf        # VPC, subnets, SGs
        ├── compute.tf        # EC2, Lambda
        ├── messaging.tf      # SQS, SNS
        ├── storage.tf        # S3, SSM
        └── iam.tf            # Roles, policies
```

## Troubleshooting

### State Lock

```bash
terraform force-unlock LOCK_ID
```

### Cost Overruns

```bash
terraform destroy -var="scale_multiplier=50" -auto-approve
```

### Orphaned Resources

If resources exist without state, use AWS CLI to list and delete:

```bash
# Find resources by tag
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=overmind-scale-test \
  --query 'ResourceTagMappingList[].ResourceARN'
```
