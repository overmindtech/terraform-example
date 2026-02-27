# Investigator Live Query Tools — Scale Test

Tests whether the investigator can use live infrastructure query tools to catch risks that are invisible in the blast radius alone: dangling references and cross-resource value mismatches.

## What This Tests

A configurable number of service stacks (default 20) are deployed, each with an internal NLB, target group, listener, and Route53 alias record. In the change phase, a subset of Route53 records (default 6) are switched from NLB aliases to hardcoded A records pointing to non-existent private IPs (`10.0.99.X`).

**Why this is hard without live query tools:** The hardcoded IPs don't belong to any resource. They won't appear in the blast radius. Without live queries, the investigator can only see silence — no evidence that the IPs are valid or invalid. With live query tools, it can search for resources at those IPs and get an explicit "not found".

**Why the mix matters:** The 14 healthy services stay unchanged. The investigator should only live-query the 6 records that changed to hardcoded IPs — not all 20. If it queries everything, that's the performance problem we're looking for.

## Directory Structure

```
investigator-live-query/
├── README.md
├── 00_setup/       # Baseline: all Route53 records are NLB aliases
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   └── backend.tf
└── 01_change/      # Breakage: subset of records switch to hardcoded IPs
    ├── main.tf
    ├── variables.tf  # adds broken_indices variable
    ├── outputs.tf
    ├── versions.tf
    └── backend.tf    # same state key as 00_setup/
```

Both directories share the same S3 backend key so that `terraform plan` in `01_change/` produces a diff against the `00_setup/` baseline.

## Test Execution

### 1. Deploy the baseline

```bash
cd 00_setup
terraform init
terraform apply -var="service_count=20"
```

### 2. Plan the change (this is the run Overmind analyzes)

```bash
cd ../01_change
terraform init
overmind terraform plan -- -var="service_count=20"
```

The plan will show:
- **6 destroyed:** `aws_route53_record.svc["00"]`, `["03"]`, `["07"]`, `["11"]`, `["14"]`, `["18"]` (alias records removed)
- **6 created:** `aws_route53_record.svc_dangling["00"]`, `["03"]`, etc. (hardcoded A records with `10.0.99.X` IPs)
- **All NLBs, target groups, listeners: no changes**

### 3. Check Honeycomb

Look for `NewQueryTool` invocations in investigation spans to confirm live query tools were used.

### 4. Compare with feature flag off

Run the same plan with the live query feature flag disabled. Confirm no live query tool calls and similar latency to baseline.

### 5. Scale up

```bash
# In 00_setup/
terraform apply -var="service_count=50"

# In 01_change/
overmind terraform plan -- -var="service_count=50" -var='broken_indices=[0,3,7,11,14,18,22,27,33,38,42,47]'
```

### 6. Tear down

```bash
cd 00_setup
terraform destroy -var="service_count=20"
```

## Variables

| Variable | Default | Description |
|---|---|---|
| `service_count` | `20` | Number of service stacks (NLB + TG + listener + DNS) |
| `broken_indices` | `[0,3,7,11,14,18]` | Which services get broken DNS (01_change only) |

## What to Validate

| Question | How to answer |
|---|---|
| Did the investigator flag the dangling IPs? | Risk output: broken services should have `is_risk_real: true` |
| Did it use live query tools? | Honeycomb: `NewQueryTool` invocations in investigation spans |
| Did it query selectively? | Count tool invocations — should be ~6, not ~20 |
| Did it stay within time budget? | Compare total investigation duration against target |
| Does the kill switch work? | Feature flag off → no live query calls, similar latency |

## Cost Estimate

Each internal NLB costs ~$22/month. At 20 services that's ~$440/month, at 50 services ~$1,100/month. Tear down promptly after testing.
