# Test Scenarios

Scenarios modify infrastructure to trigger specific risks in Overmind. Each scenario is applied on top of the baseline infrastructure.

## Quick Start

```bash
# 1. Apply baseline infrastructure
terraform apply -var="scale_multiplier=10" -var="scenario=none"

# 2. Plan with scenario (sends to Overmind for analysis)
terraform plan -var="scale_multiplier=10" -var="scenario=shared_sg_open"

# 3. Try different scenarios
terraform plan -var="scale_multiplier=10" -var="scenario=vpc_peering_change"

# 4. Destroy when done
terraform destroy -var="scale_multiplier=10"
```

## Scenario Summary

### Standard Scenarios

| Scenario | Category | Severity | Description |
|----------|----------|----------|-------------|
| `sg_open_ssh` | Security | High | Opens SSH (port 22) from 0.0.0.0/0 |
| `sg_open_all` | Security | Critical | Opens all ports from 0.0.0.0/0 |
| `ec2_downgrade` | Performance | Medium | Downgrades EC2 from t3.micro to t3.nano |
| `lambda_timeout` | Reliability | Medium | Reduces Lambda timeout to 1 second |

### High Fan-Out Scenarios

| Scenario | Category | Blast Radius (10x) | Blast Radius (50x) |
|----------|----------|-------------------|-------------------|
| `shared_sg_open` | Security | ~169 items | ~800+ items |
| `vpc_peering_change` | Network | ~800+ items | ~4000+ items |

## Standard Scenarios

### sg_open_ssh

Opens SSH to the internet on individual security groups.

| Attribute | Value |
|-----------|-------|
| Category | Security |
| Severity | High |
| Change | Adds port 22 ingress from 0.0.0.0/0 |
| Blast Radius | Low (~20-30 items at 10x) |

### sg_open_all

Opens all ports to the internet.

| Attribute | Value |
|-----------|-------|
| Category | Security |
| Severity | Critical |
| Change | Adds ports 0-65535 ingress from 0.0.0.0/0 |
| Blast Radius | Low (~20-30 items at 10x) |

### ec2_downgrade

Downgrades EC2 instance types.

| Attribute | Value |
|-----------|-------|
| Category | Performance |
| Severity | Medium |
| Change | Changes t3.micro to t3.nano |
| Blast Radius | Low (~20 items at 10x) |

### lambda_timeout

Reduces Lambda function timeout.

| Attribute | Value |
|-----------|-------|
| Category | Reliability |
| Severity | Medium |
| Change | Sets timeout to 1 second |
| Blast Radius | Low (~30 items at 10x) |

## High Fan-Out Scenarios

These scenarios modify shared resources that many other resources depend on.

### shared_sg_open

Opens SSH on the **shared** security group that all EC2 instances use.

| Attribute | Value |
|-----------|-------|
| Category | Security |
| Severity | Critical |
| Change | Adds port 22 ingress from 0.0.0.0/0 to shared SG |

**Why High Blast Radius:** The shared SG is attached to ALL EC2 instances in each region.

**Validated Results:**

| Multiplier | EC2 Instances | Blast Radius |
|------------|---------------|--------------|
| 1x | 4 | 38 items |
| 10x | 40 | 169 items |
| 50x | 200 | ~800 items |

### vpc_peering_change

Modifies VPC peering connection DNS settings.

| Attribute | Value |
|-----------|-------|
| Category | Network |
| Severity | Medium |
| Change | Enables DNS resolution on VPC peering |

**Why High Blast Radius:** VPC peering connects two entire VPCs. Modifying a peering affects all resources in both VPCs.

**Architecture:**

```
VPC PEERING MESH

  us-east-1 <----------> us-west-2
      |                      |
      |                      |
  eu-west-1 <----------> ap-southeast-1

  6 peering connections forming a full mesh.
  Modifying one peering affects resources in 2 VPCs.
```

**Expected Results:**

| Multiplier | Resources per VPC | Blast Radius |
|------------|-------------------|--------------|
| 1x | ~100 | ~400 items |
| 10x | ~435 | ~800 items |
| 50x | ~2000 | ~4000 items |

## Validation Checklist

For each scenario, verify:

- Risk is detected with correct type and severity
- Blast radius shows affected resources
- Relationship traversal works (SG to EC2 to EBS)
- Analysis completes without timeout

## File Structure

```
scale-test/
├── scenario_security.tf      # sg_open_ssh, sg_open_all
├── scenario_compute.tf       # ec2_downgrade
├── scenario_lambda.tf        # lambda_timeout
├── scenario_high_fanout.tf   # shared_sg_open
└── scenario_vpc_peering.tf   # vpc_peering_change
```

## Removed Scenarios

| Scenario | Reason |
|----------|--------|
| iam_broadening | New resources have no ARN until apply |
| shared_iam_admin | New IAM policy has no ARN until apply |
| ec2_start_all | Cost risk at scale |
| ec2_upgrade | Cost risk at scale |
