# Signals Demo

This module demonstrates Overmind's **Signals** feature—the ability to identify abnormal infrastructure changes buried within routine modifications that human reviewers typically miss.

## What This Demo Shows

We simulate a B2B SaaS company that maintains customer IP whitelists for API access. The demo has two scenarios:

1. **Clean Scenario**: Just routine customer IP whitelist updates. Overmind recognizes the pattern and marks it as low-risk/auto-approvable.

2. **Needle Scenario**: Same routine updates, but a teammate also "tightened security" by narrowing an internal CIDR from `10.0.0.0/8` to `10.0.0.0/16` (the baseline VPC CIDR). This looks like a security improvement and passes all policy checks, but it breaks connectivity from a peered “shared services/monitoring” VPC that previously relied on that broader range. Overmind flags this as unusual (the internal SG is rarely modified) and shows the blast radius.

## The Risk Explained

### What Looks Safe (But Isn't)

The "needle" scenario includes a change that appears to be a security improvement:

```hcl
# Before
internal_cidr = "10.0.0.0/8"

# After (the "security hardening")
internal_cidr = "10.0.0.0/16"
```

**Why it looks good:**
- More restrictive CIDR (smaller range)
- Passes policy checks ("more restrictive = better")
- Security audit recommended it
- Matches the VPC CIDR

**Why it's actually dangerous:**
- A peered/shared services VPC (e.g. `10.50.0.0/16`) can no longer reach the API server on internal ports
- Internal tooling and monitoring lose connectivity (e.g., metrics scraping on port 9090)
- **AWS metadata shows the breakage**: the monitoring VPC’s internal NLB target health flips to unhealthy

### What Actually Breaks

When `internal_cidr` is narrowed from `10.0.0.0/8` to `10.0.0.0/16`, here's what happens:

1. **Peered Monitoring/Shared-Services Connectivity Breaks**
   - A Terraform-managed “monitoring” VPC (CIDR `10.50.0.0/16`) is peered to the workload VPC (`10.0.0.0/16`)
   - With the broad `/8`, the API’s `internal_services` SG allows the monitoring VPC to reach port 9090
   - After narrowing to the workload VPC `/16`, traffic from the monitoring VPC is blocked by the SG

2. **AWS-managed Health Signal Flips**
   - The monitoring VPC’s internal NLB health-checks the API instance over the peering link
   - Target health changes from **healthy → unhealthy**, visible via ELBv2 target health and CloudWatch metrics

3. **The Silent Failure**
   - Customers don't notice (they use the customer-facing security group)
   - The API continues to work
   - But monitoring/observability paths from the shared services VPC are broken
   - If a real issue occurs, no one will know until customers complain

### Why Traditional Policy Checks Miss This

Standard infrastructure policy checks would **approve** this change because:

- ✅ More restrictive security group rules
- ✅ Follows security best practices (principle of least privilege)
- ✅ Matches audit recommendations
- ✅ No syntax errors
- ✅ No obvious security vulnerabilities

**But they miss the operational impact:**
- ❌ Doesn't check historical change patterns
- ❌ Doesn't understand service dependencies
- ❌ Doesn't know that this SG rarely changes
- ❌ Doesn't trace the blast radius

### How Overmind Signals Detects It

Overmind's Signals feature uses **pattern recognition** to identify unusual changes:

1. **Historical Analysis**: Overmind sees that `internal_services` security group has been modified only a few times in the past 6 months, while `customer_access` changes multiple times per week.

2. **Anomaly Detection**: When both security groups change in the same PR, Overmind flags the `internal_services` change as unusual—even though it passes policy checks.

3. **Blast Radius Visualization**: Overmind traces the dependency chain:
   ```
   internal_services SG change
   → api_server (uses this SG)
   → monitoring_vpc (peered shared-services VPC)
   → internal_nlb (health-checks the API over peering)
   → target_health (healthy → unhealthy)
   ```

4. **Risk Assessment**: Overmind recognizes that changing a rarely-modified, critical security group that affects monitoring infrastructure is high-risk, regardless of whether it's "more secure."

## Prerequisites

- AWS account with appropriate permissions
- GitHub repository with Actions enabled
- Overmind connected to the repository
- Terraform >= 1.5.0
- Domain name for Route53 (optional; this module includes Route53 resources but the demo proof does not rely on public health checks)

## Running a Demo

### Before the Demo (5 minutes prior)

This repo uses a single GitHub Actions workflow to generate the demo changes:

- **Routine mode (scheduled)**: broadens one customer allowlist CIDR (or adds a new customer) and commits directly to `main` (no PR)
- **Needle mode (manual)**: runs the same routine update **and** tightens the internal CIDR, then opens a PR (no terraform plan/apply in this workflow)
 
In routine mode, the allowlist changes are intentionally **non-breaking**: each run broadens the **first** customer CIDR it finds that can be widened (superset of the previous range). Once existing customers are “broad enough”, the workflow adds a new customer entry instead. This keeps the churn realistic without cutting off existing clients.

#### Setup checklist

Before running the demo workflow, ensure the repository has:

- `GH_PAT` secret with permission to push branches and open PRs (repo `contents:write` + `pull_request` scopes as needed)
- `OVM_API_KEY` secret (for Overmind analysis in the downstream plan workflows)
- `TERRAFORM_DEPLOY_ROLE` repo variable (used by the terraform init action in routine mode)

#### Create the Needle Scenario PR (recommended for demos)

1. Go to **Actions** → **Update Customer IP Ranges**
2. Click **Run workflow**
3. Set **include_needle** to `true`
4. Wait for the workflow to open a PR titled:
   - `security: narrow internal ingress CIDR (JIRA-4521)`

#### Trigger the Clean Scenario (routine baseline)

- Either wait for the scheduled run, or manually run the same workflow with **include_needle** set to `false`.
- This path commits directly to `main` (it is intended to build the “routine change” baseline over time).

### During the Demo

#### Clean Scenario

1. Show the repeated customer allowlist CIDR updates landing on `main` over time (routine churn).
2. Show Overmind's analysis: "Routine pattern detected, low risk"
3. Point out this could be auto-approved
4. **Key talking point**: "Overmind recognizes this pattern—customer IP changes happen repeatedly. This is normal."

#### Needle Scenario

1. Open the PR
2. Show the PR description—looks legitimate ("security hardening per audit")
3. Show Overmind's analysis:
   - Customer IP changes: ✅ Routine, low risk
   - Internal SG change: ⚠️ **Unusual, high risk**
4. Expand the blast radius visualization
5. **Key talking points**:
   - "Policy checks would pass this—it's more restrictive"
   - "But Overmind knows this SG hasn't changed in months"
   - "And shows exactly what's affected: the API server, the health checks, the alerting chain"
   - "This would break monitoring, but customers wouldn't notice until it's too late"

### After the Demo

Close the PR when you're done (or merge it if you want to demonstrate the downstream effects).

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Blast Radius                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  aws_security_group.internal_services  ← THE NEEDLE         │
│           │                                                 │
│           ▼                                                 │
│  aws_instance.api_server (production-api-server)            │
│           │                                                 │
│           └──► vpc_peering_connection                        │
│                     │                                       │
│                     ▼                                       │
│                monitoring_vpc (10.50.0.0/16)                │
│                     │                                       │
│                     ▼                                       │
│                internal_nlb target_health                   │
│                (healthy → unhealthy)                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Cost

Estimated monthly cost: **~$3-5**

- `t4g.nano` instance: ~$3/month
- Elastic IP: Free (when attached to instance)
- Internal NLB: varies by region/usage (kept small for demo)
- Route53 hosted zone/health check: optional (not required for the demo proof)
- Everything else: Free tier

## Troubleshooting

### Overmind not analyzing PRs

- Verify Overmind is installed on the repository
- Check the Overmind app has permissions to read PRs
- Ensure `OVM_API_KEY` secret is set in repository settings

### Routine pattern not detected

- Ensure the routine job has run at least 3-4 times
- Check Overmind's pattern detection settings
- Verify the `customer-access` security group is being modified in routine updates

### Terraform state issues

- State is stored locally by default in the module directory
- For team use, configure an S3 backend in `versions.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-tfstate-bucket"
    key            = "signals-demo/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}
```

### Health checks failing immediately

- The demo proof uses an **internal NLB target health** check from a peered VPC.\n+  - In AWS: check the target group health for the monitoring NLB.\n+  - In Terraform: see outputs `signals_monitoring_nlb_dns_name` and `signals_monitoring_target_group_arn`.\n+- The API instance runs a small health endpoint on port **9090** via `user_data` for deterministic target health.

## Technical Deep Dive

### Why 10.0.0.0/8 vs 10.0.0.0/16 Matters

- `10.0.0.0/8` covers the full 10/8 private range (16,777,216 addresses)\n+  (RFC1918 also includes `172.16.0.0/12` and `192.168.0.0/16`.)
- `10.0.0.0/16` covers only the workload VPC (65,536 addresses)
- Shared services/monitoring components often run in separate networks or VPCs (e.g., a peered `10.50.0.0/16`)
- Narrowing to only the workload VPC CIDR breaks connectivity from those external-but-private networks

### The Dependency Chain

The blast radius visualization shows how a single security group change cascades:

1. **Direct Impact**: `api_server` loses connectivity from monitoring systems
2. **Health Check Impact**: Internal NLB target health flips to unhealthy (AWS-native evidence)
3. **Operational Impact**: Monitoring/observability signals from the shared services VPC can go dark even while customers still have access

### Pattern Recognition in Action

Overmind builds a baseline of "normal" changes by analyzing:

- **Frequency**: How often each resource type changes
- **Context**: What other resources change together
- **Timing**: When changes typically occur
- **Magnitude**: How significant the changes are

When a change deviates from this baseline, Overmind flags it—even if it passes all policy checks.

## Further Reading

- [Overmind Signals Documentation](https://docs.overmind.tech)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Route53 Health Checks](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating.html)
