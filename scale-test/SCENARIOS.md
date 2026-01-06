# Test Scenarios for Overmind Risk Detection

This directory contains test scenarios that modify infrastructure to trigger specific risks in Overmind. Each scenario is designed to test risk detection, blast radius analysis, and cost signal generation.

## Quick Start

```bash
# Apply base infrastructure (no scenario)
terraform apply -var="scale_multiplier=1"

# Apply with a scenario to trigger risks
terraform apply -var="scale_multiplier=1" -var="scenario=sg_open_ssh"

# Reset to baseline (remove scenario)
terraform apply -var="scale_multiplier=1" -var="scenario=none"
```

## Scenario Reference

### Security Scenarios

#### `sg_open_ssh` - Open SSH to the Internet

| Attribute | Value |
|-----------|-------|
| **Category** | Security |
| **Severity** | High |
| **Reversible** | ✅ Yes |
| **Change** | Adds ingress rule allowing port 22 from 0.0.0.0/0 to shared security groups |

**Expected Risks:**
- Security exposure: SSH open to internet
- Blast radius: All EC2 instances in affected security groups

**Expected Blast Radius by Multiplier:**

| Multiplier | Security Groups Affected | EC2 Instances Affected | Total Resources in Blast |
|------------|-------------------------|------------------------|-------------------------|
| 1 | 4 (1 per region) | 4 | ~20 |
| 10 | 4 | 40 | ~200 |
| 100 | 4 | 400 | ~2,000 |

---

#### `sg_open_all` - Open All Ports to the Internet

| Attribute | Value |
|-----------|-------|
| **Category** | Security |
| **Severity** | Critical |
| **Reversible** | ✅ Yes |
| **Change** | Adds ingress rule allowing all ports (0-65535) from 0.0.0.0/0 |

**Expected Risks:**
- Critical security exposure: All ports open to internet
- Blast radius: All EC2 instances in affected security groups

**Expected Blast Radius by Multiplier:**

| Multiplier | Security Groups Affected | EC2 Instances Affected | Total Resources in Blast |
|------------|-------------------------|------------------------|-------------------------|
| 1 | 4 (1 per region) | 4 | ~20 |
| 10 | 4 | 40 | ~200 |
| 100 | 4 | 400 | ~2,000 |

---

### Compute Scenarios

#### `ec2_start_all` - Start All Stopped Instances

| Attribute | Value |
|-----------|-------|
| **Category** | Cost / Operations |
| **Severity** | Medium (Cost), Low (Risk) |
| **Reversible** | ✅ Yes |
| **Change** | Changes EC2 instance state from `stopped` to `running` |

**Expected Signals:**
- **Cost increase**: $0 → $X/month (instances now running)
- Operational change: Instances starting up
- Blast radius: All instance dependencies (volumes, ENIs, security groups)

**Expected Cost Impact by Multiplier:**

| Multiplier | EC2 Instances | Instance Type | Est. Monthly Cost (us-east-1) |
|------------|---------------|---------------|-------------------------------|
| 1 | 4 | t3.micro | ~$30/month |
| 10 | 40 | t3.micro | ~$300/month |
| 100 | 400 | t3.micro | ~$3,000/month |

*Note: Costs vary by region. Run `terraform plan` with Infracost for accurate estimates.*

---

#### `ec2_downgrade` - Downgrade Instance Type

| Attribute | Value |
|-----------|-------|
| **Category** | Performance |
| **Severity** | Medium |
| **Reversible** | ✅ Yes |
| **Change** | Changes EC2 instance type from `t3.micro` to `t3.nano` |

**Expected Risks:**
- Performance degradation: Reduced CPU/memory
- Capacity risk: May not handle expected load

**Expected Blast Radius by Multiplier:**

| Multiplier | EC2 Instances Modified | Memory Reduction | vCPU Change |
|------------|------------------------|------------------|-------------|
| 1 | 4 | 1GB → 0.5GB | 2 → 2 |
| 10 | 40 | 1GB → 0.5GB | 2 → 2 |
| 100 | 400 | 1GB → 0.5GB | 2 → 2 |

---

#### `ec2_upgrade` - Upgrade Instance Type (Cost Increase)

| Attribute | Value |
|-----------|-------|
| **Category** | Cost |
| **Severity** | Low (Risk), High (Cost) |
| **Reversible** | ✅ Yes |
| **Change** | Changes EC2 instance type from `t3.micro` to `c5.large` |

**Expected Signals:**
- **Cost increase**: Significant increase in instance costs
- Over-provisioning: May be unnecessary for workload

**Expected Cost Impact by Multiplier:**

| Multiplier | EC2 Instances | Old Type | New Type | Monthly Cost Delta |
|------------|---------------|----------|----------|-------------------|
| 1 | 4 | t3.micro | c5.large | +$200/month |
| 10 | 40 | t3.micro | c5.large | +$2,000/month |
| 100 | 400 | t3.micro | c5.large | +$20,000/month |

---

### IAM Scenarios

#### `iam_broadening` - Overly Permissive IAM Policy

| Attribute | Value |
|-----------|-------|
| **Category** | Security / IAM |
| **Severity** | Critical |
| **Reversible** | ✅ Yes |
| **Change** | Adds `*:*` (all actions on all resources) to Lambda execution role policies |

**Expected Risks:**
- Permission escalation: Roles can now do anything
- Privilege creep: Violates least-privilege principle
- Blast radius: All Lambdas using the affected roles

**Expected Blast Radius by Multiplier:**

| Multiplier | IAM Roles Affected | Lambda Functions Affected | Potential Actions Granted |
|------------|-------------------|---------------------------|---------------------------|
| 1 | 12 (3 per region) | 8 (2 per region) | All AWS actions |
| 10 | 12 | 80 | All AWS actions |
| 100 | 12 | 800 | All AWS actions |

---

### Lambda Scenarios

#### `lambda_timeout` - Reduce Lambda Timeout

| Attribute | Value |
|-----------|-------|
| **Category** | Reliability |
| **Severity** | Medium |
| **Reversible** | ✅ Yes |
| **Change** | Reduces Lambda timeout from 30 seconds to 1 second |

**Expected Risks:**
- Function failure risk: Functions may timeout before completing
- Reliability degradation: Increased error rate expected

**Expected Blast Radius by Multiplier:**

| Multiplier | Lambda Functions Affected | Downstream Resources |
|------------|---------------------------|---------------------|
| 1 | 8 (2 per region) | SQS queues, SNS topics |
| 10 | 80 | SQS queues, SNS topics |
| 100 | 800 | SQS queues, SNS topics |

---

## Validation Checklist

For each scenario, validate that Overmind:

### Risk Detection
- [ ] Identifies the correct risk type
- [ ] Assigns appropriate severity
- [ ] Provides actionable description

### Blast Radius
- [ ] Shows affected resources
- [ ] Relationship traversal works (e.g., SG → EC2 → EBS)
- [ ] Count matches expected (see tables above)

### Cost Signals (where applicable)
- [ ] Cost delta is calculated
- [ ] Direction is correct (increase/decrease)
- [ ] Magnitude is reasonable

### Performance (for high-resource scenarios)
- [ ] Plan analysis completes in reasonable time
- [ ] No timeouts at 10x or 100x multiplier
- [ ] Adapter call count is proportional (not exponential)

---

## Scenario Architecture

```
scenarios/
├── README.md           # This file
├── security.tf         # sg_open_ssh, sg_open_all
├── compute.tf          # ec2_start_all, ec2_downgrade, ec2_upgrade
├── iam.tf              # iam_broadening
└── lambda.tf           # lambda_timeout
```

Each scenario file uses conditional resources:

```hcl
resource "aws_security_group_rule" "scenario_open_ssh" {
  count = var.scenario == "sg_open_ssh" ? 1 : 0
  # ... risky configuration
}
```

When `scenario = "none"` (default), no scenario resources are created.

---

## Future Scenarios (Phase 2)

These require modifications to base infrastructure for relationship density:

| Scenario | Requirement | Expected Fan-Out |
|----------|-------------|------------------|
| `shared_sg_change` | 1 SG → 50+ instances | High |
| `shared_iam_role` | 1 role → 50+ consumers | High |
| `shared_kms_key` | 1 key → 100+ encrypted resources | Very High |

See ticket PRD-XXX for high fan-out scenario implementation.

