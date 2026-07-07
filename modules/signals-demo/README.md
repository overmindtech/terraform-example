# Signals Demo

This module demonstrates Overmind's **Signals** feature—the ability to identify abnormal infrastructure changes buried within routine modifications that human reviewers typically miss.

## What This Demo Shows

We simulate a B2B SaaS company that maintains customer IP whitelists for API access. The demo has two scenarios:

1. **Clean Scenario**: Just routine customer IP whitelist updates. Overmind recognizes the pattern and marks it as low-risk/auto-approvable.

2. **Needle Scenario**: Same routine updates, but a teammate also "tightened security" by narrowing an internal CIDR from `10.0.0.0/8` to `10.0.0.0/16` (the baseline VPC CIDR). This looks like a security improvement and passes all policy checks, but it cuts off the regulated transaction feed (port 9090, PCI scope) consumed by a peered fraud-detection VPC owned by the Risk team — a dependency that previously relied on that broader range and is only discoverable by live infrastructure traversal, not by reading Terraform. Overmind flags this as unusual (the internal SG is rarely modified) and shows the blast radius.

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
- A peered, regulated fraud-detection VPC (`10.50.0.0/16`, owned by the Risk team) can no longer reach the API server on port 9090
- That port carries the regulated transaction feed (PCI scope) the fraud-detection service depends on to score transactions in near-real-time
- The only remaining path for that data is the API server's **public** endpoint — moving regulated data outside the approved private network boundary, which is a compliance violation, not just an outage
- **AWS metadata shows the breakage**: the fraud-detection VPC's internal NLB target health flips to unhealthy

### What Actually Breaks

When `internal_cidr` is narrowed from `10.0.0.0/8` to `10.0.0.0/16`, here's what happens:

1. **Peered Fraud-Detection Connectivity Breaks**
   - A Terraform-managed fraud-detection VPC (CIDR `10.50.0.0/16`), owned by the Risk team, is peered to the core VPC (`10.0.0.0/16`)
   - With the broad `/8`, the API's `internal_services` SG allows the fraud-detection VPC to reach port 9090 (the regulated transaction feed)
   - After narrowing to the core VPC `/16`, traffic from the fraud-detection VPC is blocked by the SG — with no Terraform reference anywhere tying the two together

2. **AWS-managed Health Signal Flips**
   - The fraud-detection VPC's internal NLB (`fraud-ingest`) health-checks the API instance over the peering link
   - Target health changes from **healthy → unhealthy**, visible via ELBv2 target health and CloudWatch metrics

3. **The Compliance Failure, Not Just an Outage**
   - Customers don't notice (they use the customer-facing security group)
   - The API continues to work
   - But the fraud-detection service loses its only compliant private path to regulated transaction data
   - If it fails over to the public endpoint, or simply stops receiving data, no one on the core platform team would know — they've never heard of the fraud-detection VPC

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
   → api_server (uses this SG, emits the regulated transaction feed on :9090)
   → vpc_peering_connection (fraud_detection_to_core)
   → fraud_detection_vpc (regulated, Risk-team-owned)
   → fraud_ingest NLB (pulls the feed across the peering)
   → target_health (healthy → unhealthy)
   → fraud_processor (the actual downstream consumer losing the feed)
   ```

4. **Risk Assessment (without knowledge)**: Overmind recognizes that changing a rarely-modified, critical security group that affects a live cross-VPC dependency is high-risk, regardless of whether it's "more secure" — but the finding is still generic ("may disconnect the fraud-detection VPC across the peering connection").

5. **Risk Assessment (with the knowledge file)**: once `.overmind/knowledge/cross-vpc-regulated-feed.md` is present, the same finding sharpens into a named compliance violation (public-internet fallback for regulated data), references the past incident that led to this exact CIDR scoping, and names the Risk team to loop in — a materially higher-severity, more actionable verdict for the *same* underlying change.

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
   - "And shows exactly what's affected: the API server, the peering connection, the fraud-detection VPC, the NLB target health"
   - "Without any extra context, that's already a real, high-severity finding a plan-only tool can't produce"
   - "Now watch what happens when we add one knowledge file: the same finding gets sharper—it names the compliance boundary this breaks, the past incident that caused this exact scoping, and the team to loop in"
   - "This would break the fraud-detection team's only compliant path to this data, but customers wouldn't notice until it's too late"

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
│  emits regulated transaction feed on :9090 (PCI scope)      │
│           │                                                 │
│           └──► vpc_peering_connection (fraud_detection_to_core) │
│                     │                                       │
│                     ▼                                       │
│                fraud_detection_vpc (10.50.0.0/16)           │
│                Risk team, regulated (PCI-DSS)                │
│                     │                                       │
│                     ▼                                       │
│                fraud_ingest NLB target_health                │
│                (healthy → unhealthy)                        │
│                     │                                       │
│                     ▼                                       │
│                fraud_processor (downstream consumer)         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Cost

Estimated monthly cost: **~$6-9**

- `t4g.nano` API server instance: ~$3/month
- `t4g.nano` fraud-processor instance: ~$3/month
- Elastic IP: Free (when attached to instance)
- Internal NLB: varies by region/usage (kept small for demo)
- VPC Flow Logs (CloudWatch Logs, 90-day retention): a few cents/month at this traffic volume
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

- The demo proof uses an **internal NLB target health** check from a peered, regulated VPC.\n+  - In AWS: check the target group health for the `fraud-ingest` NLB.\n+  - In Terraform: see outputs `signals_fraud_ingest_nlb_dns_name` and `signals_txn_feed_target_group_arn`.\n+- The API instance runs a small health endpoint on port **9090** via `user_data` for deterministic target health.

## Technical Deep Dive

### Why 10.0.0.0/8 vs 10.0.0.0/16 Matters

- `10.0.0.0/8` covers the full 10/8 private range (16,777,216 addresses)\n+  (RFC1918 also includes `172.16.0.0/12` and `192.168.0.0/16`.)
- `10.0.0.0/16` covers only the core VPC (65,536 addresses)
- The regulated fraud-detection VPC runs in a separate, peered network (`10.50.0.0/16`) owned by a different team
- Narrowing to only the core VPC CIDR breaks the regulated feed's only private, compliant path — see `.overmind/knowledge/cross-vpc-regulated-feed.md` for why that scoping is intentional, not accidental

### The Dependency Chain

The blast radius visualization shows how a single security group change cascades:

1. **Direct Impact**: `api_server` loses the ability to serve the regulated transaction feed to the fraud-detection VPC
2. **Health Check Impact**: Internal NLB target health flips to unhealthy (AWS-native evidence)
3. **Compliance Impact**: The fraud-detection service's only private, compliant path to regulated data breaks; the only fallback is the public endpoint, which is out of the approved network boundary

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
