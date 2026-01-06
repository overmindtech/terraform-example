# Test Scenarios for Overmind Risk Detection

This directory contains test scenarios that modify infrastructure to trigger specific risks in Overmind. Each scenario is designed to test risk detection, blast radius analysis, and cost signal generation.

## Quick Start

```bash
# Step 1: Apply base infrastructure (no scenario)
terraform apply -var="scale_multiplier=1" -var="scenario=none"

# Step 2: Run plan with scenario (tests risk detection)
terraform plan -var="scale_multiplier=1" -var="scenario=sg_open_ssh"

# Step 3: Try different scenarios
terraform plan -var="scale_multiplier=1" -var="scenario=shared_sg_open"

# Step 4: Destroy when done
terraform destroy -var="scale_multiplier=1"
```

## Scenario Categories

### Standard Scenarios (Low-Medium Blast Radius)

| Scenario | Category | Severity | Blast Radius at 1x |
|----------|----------|----------|-------------------|
| `sg_open_ssh` | Security | High | ~20-30 items |
| `sg_open_all` | Security | Critical | ~20-30 items |
| `ec2_downgrade` | Performance | Medium | ~20 items |
| `lambda_timeout` | Reliability | Medium | ~30 items |

### High Fan-Out Scenarios (Large Blast Radius) 🔥

| Scenario | Category | Severity | Blast Radius at 1x | at 10x | at 100x |
|----------|----------|----------|-------------------|--------|---------|
| `shared_sg_open` | Security | Critical | ~38 items | ~169 items | **~1500+ items** |

---

## Standard Scenarios

### `sg_open_ssh` - Open SSH to Internet

| Attribute | Value |
|-----------|-------|
| **Category** | Security |
| **Severity** | High |
| **Reversible** | ✅ Yes |
| **Change** | Adds SSH (port 22) ingress rule from 0.0.0.0/0 to individual security groups |

**Why Low Blast Radius:** Modifies individual SGs that each have ~1-2 EC2 instances attached.

---

### `sg_open_all` - Open All Ports to Internet

| Attribute | Value |
|-----------|-------|
| **Category** | Security |
| **Severity** | Critical |
| **Reversible** | ✅ Yes |
| **Change** | Adds all ports (0-65535) ingress rule from 0.0.0.0/0 |

---

### `ec2_downgrade` - Downgrade Instance Type

| Attribute | Value |
|-----------|-------|
| **Category** | Performance |
| **Severity** | Medium |
| **Reversible** | ✅ Yes |
| **Change** | Changes EC2 instance type from `t3.micro` to `t3.nano` |

---

### `lambda_timeout` - Reduce Lambda Timeout

| Attribute | Value |
|-----------|-------|
| **Category** | Reliability |
| **Severity** | Medium |
| **Reversible** | ✅ Yes |
| **Change** | Reduces Lambda timeout from default to 1 second |

---

## High Fan-Out Scenarios 🔥

These scenarios modify **shared resources** that many other resources depend on, creating large blast radii.

### Architecture

```
HIGH FAN-OUT ARCHITECTURE:

┌──────────────────────────────────────────────────────────┐
│  SHARED SECURITY GROUP                                    │
│  (aws_security_group.high_fanout)                        │
│                                                          │
│  Attached to ALL EC2 instances in the region             │
│  At 100x: 200 EC2 instances per region                   │
└──────────────────────────────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────┼───────────────────┐
        │                   │                   │
   ┌────▼────┐         ┌────▼────┐         ┌────▼────┐
   │  EC2-1  │         │  EC2-2  │   ...   │ EC2-200 │
   │  + ENI  │         │  + ENI  │         │  + ENI  │
   │  + EBS  │         │  + EBS  │         │  + EBS  │
   └─────────┘         └─────────┘         └─────────┘

┌──────────────────────────────────────────────────────────┐
│  SHARED IAM ROLE                                          │
│  (aws_iam_role.high_fanout_lambda)                       │
│                                                          │
│  Used by ALL Lambda functions in the region              │
│  At 100x: 200 Lambda functions per region                │
└──────────────────────────────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────┼───────────────────┐
        │                   │                   │
   ┌────▼────┐         ┌────▼────┐         ┌────▼────┐
   │Lambda-1 │         │Lambda-2 │   ...   │Lambda-200│
   │  + Logs │         │  + Logs │         │  + Logs  │
   └─────────┘         └─────────┘         └─────────┘
```

### `shared_sg_open` - Open SSH on Shared Security Group

| Attribute | Value |
|-----------|-------|
| **Category** | Security |
| **Severity** | Critical |
| **Reversible** | ✅ Yes |
| **Change** | Adds SSH ingress from 0.0.0.0/0 to the **shared** security group |

**Why High Blast Radius:** The shared SG is attached to ALL EC2 instances.

**Expected Blast Radius (validated):**

| Multiplier | EC2 Instances | Queries | Total Items |
|------------|---------------|---------|-------------|
| 1x | 4 | 87 | 38 ✅ |
| 10x | 40 | 492 | 169 ✅ |
| 100x | 400 | ~5000 | **~1500+** |

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

### Performance (for high fan-out scenarios)
- [ ] Plan analysis completes in reasonable time
- [ ] No timeouts at 10x or 100x multiplier
- [ ] Blast radius scales proportionally (not exponentially)

---

## Scenario Files

```
scale-test/
├── SCENARIOS.md              # This file
├── scenario_security.tf      # sg_open_ssh, sg_open_all
├── scenario_compute.tf       # ec2_downgrade (note in file)
├── scenario_lambda.tf        # lambda_timeout (via module variable)
└── scenario_high_fanout.tf   # shared_sg_open
```

---

## Removed Scenarios

| Scenario | Reason |
|----------|--------|
| `iam_broadening` | Created new resources (ARN unknown), Overmind couldn't map |
| `shared_iam_admin` | Created new IAM policy (no ARN until apply), Overmind couldn't map |
| `ec2_start_all` | Cost risk (~$3,000/month at 100x) |
| `ec2_upgrade` | Cost risk (~$20,000/month at 100x) |
