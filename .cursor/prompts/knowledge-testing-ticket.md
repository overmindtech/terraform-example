# Overmind Knowledge - Testing & Validation

## Summary

Test the Overmind Knowledge feature end-to-end using the terraform-example repo's scale test infrastructure. We have 5 knowledge files, a dedicated GitHub Actions workflow, and a dashboard to evaluate whether knowledge files influence Overmind's risk analysis as expected across 4 categories: creating risks, lowering risks, discovering resources, and adding operational instructions.

## Background

Overmind Knowledge is a new feature that lets users place markdown files in `.overmind/knowledge/` to give Overmind security standards, compliance requirements, and best practices. During change analysis, Overmind discovers available knowledge via frontmatter metadata, activates relevant files via `GetKnowledge(name)`, and applies the guidelines when evaluating risks.

The terraform-example repo already has:
- Scale test infrastructure across 4 AWS regions with ~175-8,700 resources
- 7 AWS test scenarios that trigger specific risk patterns (SG open, Lambda timeout, VPC peering, SNS policy, KMS orphan, etc.)
- A nightly scale-test workflow that runs all scenarios and sends results to a dashboard
- PromptFoo evals for risk quality

We've added:
- 5 knowledge files in `.overmind/knowledge/` written as a realistic customer would (team-oriented, not resource-specific)
- A `knowledge-test.yml` workflow with 17 test cases across 4 categories
- A dashboard page with LLM evaluation at `/knowledge`

## What to test

### Phase 1: Pre-knowledge baseline (done / in progress)

Run the knowledge-test workflow before the CLI supports knowledge files. This gives us baseline risk outputs for all 17 test cases. The knowledge files are present in the repo but ignored by the CLI.

- [x] Workflow runs successfully on GitHub Actions
- [ ] All 17 test cases complete without errors
- [ ] Results land in the dashboard via `/api/knowledge-results`
- [ ] Dashboard `/knowledge` page populates with results

### Phase 2: Knowledge feature enabled

Once the Overmind CLI reads `.overmind/knowledge/` files, re-run the workflow and validate each category.

#### Create risk (3 test cases)

Knowledge should cause Overmind to identify NEW risks or ELEVATE severity on existing risks.

| Test ID | Scenario | What to check |
|---------|----------|---------------|
| `create-risk-sg-public-exposure` | `shared_sg_open` | Risk output should cite public subnet + public IP as compounding factors (from `security-standards.md`). Severity should be higher than baseline. Look for mentions of "public IP", "private subnet", "directly reachable". |
| `create-risk-lambda-sqs-timeout` | `lambda_timeout` | Risk output should cite the 6x SQS visibility timeout rule (from `platform-event-pipeline.md`). Should mention "180 seconds", "visibility timeout", "duplicate processing". Without knowledge, this is a generic "timeout reduced" warning. With knowledge, it should be a specific compliance violation. |
| `create-risk-kms-encryption-compliance` | `kms_orphan_simulation` | Risk output should flag S3 buckets using AES256 as non-compliant (from `security-standards.md`). Look for mentions of "KMS", "customer-managed key", "AES256", "non-compliant". The regular S3 buckets in the module use AES256, which the knowledge says is insufficient. |

**Pass criteria:** Risk count or severity increases compared to baseline. Risk descriptions reference knowledge-specific standards.

#### Lower risk (3 test cases)

Knowledge should cause Overmind to REDUCE severity or DISPROVE risks.

| Test ID | Scenario | What to check |
|---------|----------|---------------|
| `lower-risk-vpc-approved-dns` | `vpc_peering_change` | Risk should be lower or absent. `multi-region-design.md` states DNS resolution on VPC peering is approved and required for service discovery. Look for language like "approved architecture", "required for service discovery", "not a security concern". |
| `lower-risk-sns-approved-hardening` | `central_sns_change` | Risk should be lower. `platform-event-pipeline.md` states the Deny+StringNotEquals pattern is approved security hardening. Look for "approved hardening", "does not block internal publishers". |
| `lower-risk-lambda-dummy-functions` | `lambda_timeout` | Risk should be lower. `infrastructure-guide.md` states these are dummy handlers that don't process real messages. Look for "test functions", "dummy handlers", "timeout is not operationally significant". |

**Pass criteria:** Risk severity decreases or risk is dismissed compared to baseline. Risk output explains WHY using knowledge-based reasoning.

**Important A/B test:** `lambda_timeout` has BOTH a create-risk test (platform knowledge says 180s minimum) and a lower-risk test (infra-guide says dummy functions). Both knowledge files are always present. Overmind must decide which to weight more heavily. This tests knowledge conflict resolution.

#### Discover (2 test cases)

Knowledge should help Overmind find resources NOT obvious from the Terraform dependency graph.

| Test ID | Scenario | What to check |
|---------|----------|---------------|
| `discover-sns-ssm-and-publishers` | `central_sns_change` | Should mention SSM parameters under `/ovm-scale/` containing stale SNS ARN references (`multi-region-design.md`). Should also mention Lambda functions as upstream publishers via `CENTRAL_SNS_TOPIC` env var (`platform-event-pipeline.md`). These are NOT Terraform graph edges -- SSM params store ARNs as string values, Lambda functions reference the topic via env vars. |
| `discover-vpc-endpoints` | `vpc_peering_change` | Should mention S3 VPC Gateway Endpoints as affected by routing changes (`multi-region-design.md`). The dependency chain (Lambda -> route table -> VPC endpoint -> S3) is a data path, not a Terraform edge. |

**Pass criteria:** Resources mentioned in knowledge appear in the risk output or blast radius that were absent in the baseline.

#### Instruct (4 test cases)

Knowledge should add operational context (contacts, processes, URLs) to risk output WITHOUT changing the risk verdict.

| Test ID | Scenario | Specific strings to look for |
|---------|----------|------------------------------|
| `instruct-kms-security-process` | `kms_orphan_simulation` | "Sarah Chen" or "sarah.chen", "SEC-REVIEW", "Jira", "Security Engineering", "#security-incidents" |
| `instruct-sg-firewall-exception` | `shared_sg_open` | "Mike Rodriguez" or "mike.rodriguez", "firewall exception", "https://internal.acme.com/network/exceptions", "David Kim" or "david.kim", "48-hour", "VP" |
| `instruct-vpc-multi-team-signoff` | `vpc_peering_change` | "james.park", "priya.sharma", "thomas.mueller", "wei.zhang", "#cross-region-changes", "sign-off" |
| `instruct-sns-maintenance-window` | `central_sns_change` | "Tuesday", "2:00" or "2 AM", "UTC", "Platform-Primary", "#platform-ops", "https://runbooks.acme.com/event-bus-recovery" |

**Pass criteria:** Specific strings from knowledge files appear in the risk output. Risk severity should be similar to baseline (instructions don't change the verdict, they enrich it).

### Phase 3: Knowledge file quality degradation

Once Phase 2 passes, test with degraded knowledge quality to see how the system handles imperfect customer writing.

- Rewrite one knowledge file with vague language (e.g., "buckets should use good encryption" instead of "must use aws:kms with customer-managed key")
- Rewrite one with slight inaccuracies (e.g., wrong timeout threshold, slightly wrong contact name)
- Rewrite one in terse bullet-point style (minimal prose, just requirements)
- Compare results to Phase 2 to measure quality degradation curve

### Phase 4: Knowledge activation accuracy

Validate that Overmind activates the RIGHT knowledge files and ignores irrelevant ones.

- For each test case, check which knowledge files were actually activated (if the API/logs expose this)
- Verify that `shared_sg_open` activates `security-standards.md` and `change-approvals.md` but NOT `platform-event-pipeline.md` or `infrastructure-guide.md`
- Verify that `lambda_timeout` activates `platform-event-pipeline.md` and/or `infrastructure-guide.md` but NOT `multi-region-design.md`
- Check for knowledge pollution: does irrelevant knowledge appear in risk output?

## Infrastructure

### Knowledge files (`.overmind/knowledge/`)

| File | Author voice | Primary test targets |
|------|-------------|---------------------|
| `security-standards.md` | Security team, formal/policy | create-risk (SG, KMS), instruct (KMS) |
| `platform-event-pipeline.md` | Platform team, onboarding doc | create-risk (Lambda), lower-risk (SNS), instruct (SNS), discover (Lambda publishers) |
| `change-approvals.md` | Engineering manager, process doc | instruct (SG, KMS, VPC) |
| `multi-region-design.md` | Architect, design doc | lower-risk (VPC), discover (SSM, VPC endpoints) |
| `infrastructure-guide.md` | Various, wiki-style | lower-risk (Lambda) |

### Workflow

- **File:** `.github/workflows/knowledge-test.yml`
- **Schedule:** Nightly at 5 AM UTC (3 hours after scale-test)
- **Manual trigger:** `workflow_dispatch` with category filter and scale multiplier
- **Scale:** 5x by default (fast enough for 17 tests, enough blast radius)
- **Baseline comparison:** Nightly scale-test runs the same scenarios without knowledge

### Dashboard

- **API endpoint:** `POST /api/knowledge-results`
- **Pages:** `/knowledge` (overview), `/knowledge/[testId]` (detail), `/knowledge/compare/[scenario]` (comparison), `/knowledge/trends` (over time)
- **LLM evaluation:** Runs async after results land, scores PASS/PARTIAL/FAIL per test case

## Acceptance criteria

- [ ] All 17 knowledge test cases run to completion
- [ ] Dashboard receives and displays results with LLM evaluation scores
- [ ] **Create risk:** At least 2 of 3 test cases show elevated risk compared to baseline
- [ ] **Lower risk:** At least 2 of 3 test cases show reduced risk compared to baseline
- [ ] **Discover:** At least 1 of 2 test cases mentions resources not in baseline blast radius
- [ ] **Instruct:** At least 3 of 4 test cases include expected contact names or process details
- [ ] Lambda timeout A/B test (create vs lower) produces meaningfully different outputs based on which knowledge Overmind weights
- [ ] No knowledge pollution: irrelevant knowledge does not contaminate risk output for unrelated scenarios
