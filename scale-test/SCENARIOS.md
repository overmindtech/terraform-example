# Test Scenarios

Scenarios modify infrastructure to trigger specific risks in Overmind. Each scenario is applied on top of the baseline infrastructure.

## Quick Start

```bash
# 1. Apply baseline infrastructure
terraform apply -var="scale_multiplier=25" -var="scenario=none"

# 2. Plan with scenario (sends to Overmind for analysis)
terraform plan -var="scale_multiplier=25" -var="scenario=combined_network"

# 3. Try different scenarios
terraform plan -var="scale_multiplier=25" -var="scenario=vpc_peering_change"

# 4. Destroy when done
terraform destroy -var="scale_multiplier=25"
```

## Scenario Summary

| Scenario | Category | Blast Radius (10x) | Blast Radius (25x) |
|----------|----------|-------------------|-------------------|
| `shared_sg_open` | Security | ~169 items | ~400 items |
| `vpc_peering_change` | Network | ~383 items | ~852 items |
| `central_sns_change` | Messaging | ~332 items | ~478 items |
| `combined_network` | Network + Security | ~600 items | ~1,200 items |
| `combined_all` | All | ~800 items | ~1,500 items |
| `combined_max` | All + Compute | ~900+ items | ~1,500+ items |
| `kms_orphan` | Security / Data Loss | Manual test | Manual test |
| `kms_orphan_simulation` | Security / Data Loss | ~5 items | ~5 items |

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
| 25x | 100 | ~400 items |

### vpc_peering_change

Modifies VPC peering connection DNS settings.

| Attribute | Value |
|-----------|-------|
| Category | Network |
| Severity | Medium |
| Change | Enables DNS resolution on all 6 VPC peerings |

**Why High Blast Radius:** VPC peering connects two entire VPCs. Modifying a peering affects all resources in both VPCs.

**Architecture:**

```
VPC PEERING MESH

  us-east-1 <----------> us-west-2
      |                      |
      |                      |
  eu-west-1 <----------> ap-southeast-1

  6 peering connections forming a full mesh.
  Modifying all peerings affects resources in all 4 VPCs.
```

**Validated Results:**

| Multiplier | Resources per VPC | Blast Radius |
|------------|-------------------|--------------|
| 10x | ~435 | 383 items |
| 25x | ~1,100 | 852 items |
| 50x | ~2,000 | ~1,700 items (estimated) |

### central_sns_change

Modifies the central SNS topic policy that all SQS queues subscribe to.

| Attribute | Value |
|-----------|-------|
| Category | Messaging |
| Severity | High |
| Change | Modifies SNS topic policy |

**Why High Blast Radius:** The central SNS topic has subscriptions from all SQS queues across all regions.

**Validated Results:**

| Multiplier | SQS Queues | Blast Radius |
|------------|------------|--------------|
| 10x | ~150 | 332 items |
| 25x | ~380 | 478 items |

## Combined Scenarios

These scenarios trigger multiple changes simultaneously for maximum blast radius.

### combined_network

Combines `vpc_peering_change` + `shared_sg_open`.

| Attribute | Value |
|-----------|-------|
| Category | Network + Security |
| Severity | Critical |
| Changes | 6 VPC peering DNS changes + 4 shared SG rule additions |
| TF Resources | ~16 resources modified |

**Why Maximum Blast Radius:** Touches both network layer (VPC peerings affecting routing) and security layer (SGs affecting instances). The overlapping resources are counted once, but the combined risks amplify the analysis.

**Expected Results:**

| Multiplier | Expected Blast Radius |
|------------|----------------------|
| 10x | ~600 items |
| 25x | ~1,200 items |
| 50x | ~2,500 items |

### combined_all

Combines ALL high-fanout scenarios (except central_s3 which times out).

| Attribute | Value |
|-----------|-------|
| Category | All |
| Severity | Critical |
| Changes | VPC peerings + shared SGs + central SNS policy |
| TF Resources | ~20+ resources modified |

**Why Maximum Blast Radius:** Touches network, security, and messaging layers simultaneously.

**Expected Results:**

| Multiplier | Expected Blast Radius |
|------------|----------------------|
| 10x | ~800 items |
| 25x | ~1,500 items |
| 50x | ~3,000+ items |

### combined_max

Maximum blast radius scenario for stress testing. Combines everything with additional risky changes.

| Attribute | Value |
|-----------|-------|
| Category | All + Compute |
| Severity | Critical |
| Changes | VPC peerings + ALL PORTS open (not just SSH) + central SNS + Lambda timeouts |
| TF Resources | ~25+ resources modified |

**Differences from combined_all:**

- Opens ALL ports (0-65535) instead of just SSH (port 22)
- Also modifies Lambda function timeouts (reduces to 1 second)
- Creates more Terraform resources to modify, increasing plan size

**Why Even Larger Blast Radius:** 

- All ports open is a more severe security change that may trigger additional risk hypotheses
- Lambda timeout changes touch all Lambda functions and their dependencies
- More resources modified in a single plan means more starting points for blast radius calculation

**Expected Results:**

| Multiplier | Expected Blast Radius |
|------------|----------------------|
| 10x | ~900+ items |
| 25x | ~1,500+ items |
| 50x | ~3,500+ items |

## Manual Test Scenarios

These scenarios require manual intervention (state manipulation) rather than variable changes.

### kms_orphan (Manual Test)

Tests Overmind's detection of risks when KMS keys are removed from Terraform state via `terraform state rm`.

| Attribute | Value |
|-----------|-------|
| Category | Security / Data Loss |
| Severity | Critical |
| Type | Manual state manipulation |

**Background - Why This Is Dangerous:**

When users remove AWS KMS keys from Terraform state rather than properly destroying them:

1. **Orphaned resource** - The original KMS key still exists in AWS but is no longer managed by Terraform
2. **Duplicate key creation** - Terraform sees the resource definition with no corresponding state and creates a "new" key
3. **Encryption mismatch** - Existing resources (S3, EBS, RDS) remain encrypted with the old key; new resources use the new key
4. **Data loss risk** - If the orphaned key is eventually deleted (7-30 day mandatory waiting period), all data encrypted with it becomes permanently unrecoverable

**Why Users Do This:**

- AWS KMS keys cannot be immediately deleted (7-30 day mandatory waiting period)
- Users remove keys from state to reorganize modules
- Deletion protection policies prevent destruction
- Module refactoring without proper state migration

**Critical Nuance: `prevent_destroy` Does NOT Help!**

Users may have a false sense of security with `prevent_destroy` set:

```hcl
resource "aws_kms_key" "example" {
  description             = "Example KMS key"
  deletion_window_in_days = 30

  lifecycle {
    prevent_destroy = true
  }
}
```

This lifecycle rule **only blocks `terraform destroy`** - it does **NOT** block `terraform state rm`.

State removal is a state manipulation operation, not a destroy operation, so the lifecycle rule doesn't apply. The resource gets "forgotten" by Terraform while still existing in AWS, and the dangerous pattern proceeds as normal.

**The test infrastructure includes `prevent_destroy = true` to verify this behaviour.**

**Test Infrastructure:**

The baseline infrastructure creates:

- A central KMS key (`aws_kms_key.central`) with `prevent_destroy = true` and 30-day deletion window
- An S3 bucket encrypted with that key (`aws_s3_bucket.kms_encrypted`)
- An EBS volume encrypted with that key (`aws_ebs_volume.kms_encrypted`)

**Test Procedure:**

```bash
# 1. Apply baseline infrastructure
terraform apply -var="scale_multiplier=1"

# 2. Note the KMS key ARN from outputs
terraform output central_kms_key_arn

# 3. Remove the KMS key from state (simulates the dangerous pattern)
# NOTE: This works even though the key has prevent_destroy = true!
terraform state rm aws_kms_key.central[0]

# 4. Run terraform plan - Terraform wants to create a "new" KMS key
# The prevent_destroy lifecycle rule does NOT prevent this!
terraform plan -var="scale_multiplier=1"

# 5. This plan should be analyzed by Overmind
```

**Expected Plan Output:**

Terraform will show it wants to create a new KMS key, even though:
- The original key still exists in AWS
- The original key has `prevent_destroy = true`
- Resources (S3, EBS) still reference and use the original key

**Expected Overmind Behaviour:**

Overmind should detect and surface risks including:

| Risk | Description |
|------|-------------|
| Orphaned resource | The original KMS key still exists in AWS but is no longer managed |
| Duplicate key | A new key will be created while existing resources still reference the old one |
| Encryption mismatch | Resources encrypted with the old key won't be re-encrypted with the new one |
| Potential data loss | If the orphaned key is later deleted, encrypted data becomes unrecoverable |

**Blast Radius:**

| Resource | Impact |
|----------|--------|
| `aws_s3_bucket.kms_encrypted` | Data encrypted with orphaned key |
| `aws_ebs_volume.kms_encrypted` | Volume encrypted with orphaned key |
| Any other resources using the key | All data at risk |

**Variations to Test:**

| Variation | Expected Outcome |
|-----------|-----------------|
| With `prevent_destroy` lifecycle rule (default) | Pattern still occurs - state removal bypasses lifecycle rules entirely |
| Without `prevent_destroy` | Same dangerous pattern, but easier for users to accidentally destroy the orphaned key later |
| With SCPs blocking KMS deletion | Same outcome expected - SCP prevents destruction but not state removal |
| Multiple dependent resources | S3 + EBS + RDS all using the same key to verify blast radius is captured |

**Acceptance Criteria:**

- [ ] Overmind detects when a KMS key is being created that may duplicate an existing unmanaged key
- [ ] Risk explanation clearly communicates the data loss implications
- [ ] Blast radius includes all resources currently encrypted with the orphaned key

### kms_orphan_simulation

Simulates the duplicate KMS key scenario **without** requiring manual state manipulation.

| Attribute | Value |
|-----------|-------|
| Category | Security / Data Loss |
| Severity | Critical |
| Change | Creates a second KMS key tagged as a duplicate |

**Usage:**

```bash
# 1. Apply baseline infrastructure first
terraform apply -var="scale_multiplier=1"

# 2. Run plan with the simulation scenario
terraform plan -var="scale_multiplier=1" -var="scenario=kms_orphan_simulation"
```

This creates a second KMS key with explicit tagging indicating it's a duplicate, allowing Overmind to test duplicate key detection without actual state manipulation.

**What It Creates:**

- `aws_kms_key.duplicate` - A new KMS key with tags indicating it simulates an orphan scenario
- `aws_kms_alias.duplicate` - Alias with "DUPLICATE" in the name

**Expected Detection:**

Overmind should flag that:

- A new KMS key is being created
- An existing key with similar purpose already exists
- Resources encrypted with the original key won't automatically use the new key

---

## Other Scenarios

### lambda_timeout

Reduces Lambda function timeout from 30s to 1s.

| Attribute | Value |
|-----------|-------|
| Category | Reliability |
| Severity | Medium |
| Change | Sets timeout to 1 second |
| Blast Radius | ~50 items at 10x |

## Validation Checklist

For each scenario, verify:

- Risk is detected with correct type and severity
- Blast radius shows affected resources
- Relationship traversal works (SG to EC2 to EBS)
- Analysis completes without timeout

## File Structure

```
scale-test/
├── scenario_high_fanout.tf   # shared_sg_open
├── scenario_vpc_peering.tf   # vpc_peering_change
├── scenario_lambda.tf        # lambda_timeout
├── scenario_combined.tf      # combined_network, combined_all, combined_max
└── scenario_kms_orphan.tf    # kms_orphan, kms_orphan_simulation
```

## Removed Scenarios

| Scenario | Reason |
|----------|--------|
| sg_open_ssh | Low blast radius, replaced by shared_sg_open |
| sg_open_all | Low blast radius, replaced by shared_sg_open |
| ec2_downgrade | Low blast radius |
| central_s3_change | Causes investigation timeout at 25x |
| iam_broadening | New resources have no ARN until apply |
| shared_iam_admin | New IAM policy has no ARN until apply |
| ec2_start_all | Cost risk at scale |
| ec2_upgrade | Cost risk at scale |

## Test Results Summary (25x)

| Change ID | Scenario | Items | Edges | Hypotheses | Status |
|-----------|----------|-------|-------|------------|--------|
| 5bbef45a | vpc_peering_change | 852 | 1,876 | 2 proven | Success |
| 191c07af | central_sns_change | 478 | 1,501 | 2 proven | Success |
| f373b875 | central_s3_change | 614 | 1,582 | - | Timeout |

---

# GCP Scenarios

GCP scenarios require `enable_gcp = true` and a valid `gcp_project_id`.

## GCP Scenario Summary

| Scenario | Category | Description |
|----------|----------|-------------|
| `shared_firewall_open` | Security | Open SSH on shared firewall rule |
| `central_pubsub_change` | Messaging | Modify central Pub/Sub topic IAM |
| `gce_downgrade` | Compute | Downgrade GCE machine type |
| `function_timeout` | Compute | Reduce Cloud Function timeout |
| `combined_gcp_all` | All | All GCP high-fanout scenarios |

## GCP High Fan-Out Scenarios

### shared_firewall_open

Opens SSH (port 22) on the shared firewall rule that targets all GCE instances via network tag.

| Attribute | Value |
|-----------|-------|
| Category | Security |
| Severity | Critical |
| Change | Adds 0.0.0.0/0 SSH rule to shared firewall |

**Why High Blast Radius:** All GCE instances use the `scale-test` network tag, so modifying the firewall rule affects all instances.

### central_pubsub_change

Modifies the central Pub/Sub topic IAM policy that all regional subscriptions connect to.

| Attribute | Value |
|-----------|-------|
| Category | Messaging |
| Severity | High |
| Change | Adds allAuthenticatedUsers as viewer |

**Why High Blast Radius:** All regional subscriptions connect to the central topic.

## GCP Adapter Coverage Scenarios

### gce_downgrade

Changes GCE machine type from e2-micro to f1-micro.

| Attribute | Value |
|-----------|-------|
| Category | Compute |
| Severity | Low |
| Change | Machine type downgrade |

### function_timeout

Reduces Cloud Function timeout from 60s to 1s.

| Attribute | Value |
|-----------|-------|
| Category | Compute |
| Severity | Medium |
| Change | Timeout reduction |

## GCP Combined Scenario

### combined_gcp_all

Combines all GCP high-fanout scenarios for maximum blast radius.

| Attribute | Value |
|-----------|-------|
| Category | All |
| Severity | Critical |
| Changes | Firewall open + Pub/Sub IAM change |

## Enabling GCP

To enable GCP scenarios:

```bash
# Set these variables
export TF_VAR_enable_gcp=true
export TF_VAR_gcp_project_id="your-project-id"

# Apply with GCP enabled
terraform apply -var="scale_multiplier=10" -var="enable_gcp=true" -var="gcp_project_id=your-project-id"

# Run GCP scenario
terraform plan -var="scale_multiplier=10" -var="enable_gcp=true" -var="gcp_project_id=your-project-id" -var="scenario=shared_firewall_open"
```

## Lessons Applied from AWS

| AWS Lesson | GCP Application |
|------------|-----------------|
| IAM creation doesn't work | Removed SA creation scenarios |
| High fan-out is key | Shared firewall rule, central Pub/Sub |
| Modify, don't create | All scenarios modify existing resources |
| Combined scenarios amplify | combined_gcp_all combines multiple changes |
