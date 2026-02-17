# Knowledge Test Dashboard Features

## Context

We have an existing scale test dashboard (Next.js/Vercel) that tracks Overmind's risk analysis quality over time. The existing dashboard receives results from a nightly GitHub Actions workflow via `POST /api/results` and displays metrics like risk count, severity, blast radius, and eval scores per scenario.

We've now added a new feature called **Overmind Knowledge** — lightweight markdown files in `.overmind/knowledge/` that give Overmind security standards, compliance requirements, and operational context to use during infrastructure change analysis. A new GitHub Actions workflow (`knowledge-test.yml`) runs nightly and submits results to the dashboard via a new endpoint.

The goal of the dashboard work is:
1. Receive and store knowledge test results
2. Display them with comparison to no-knowledge baselines
3. Use an LLM to evaluate whether knowledge had the expected effect on each test

## New API Endpoint

### `POST /api/knowledge-results`

Receives results from the knowledge test workflow. Auth is the same as the existing `/api/results` endpoint (Bearer token via `SCALE_DASHBOARD_API_KEY`).

**Payload schema:**

```typescript
interface KnowledgeTestResult {
  runId: string;              // e.g. "12345678-create-risk-sg-public-exposure"
  testId: string;             // e.g. "create-risk-sg-public-exposure"
  testType: "knowledge";      // always "knowledge"
  scenario: string;           // e.g. "shared_sg_open", "lambda_timeout", etc.
  category: string;           // "baseline" | "create_risk" | "lower_risk" | "discover" | "instruct"
  expectedEffect: string;     // Human-readable description of what knowledge should do
  relevantKnowledge: string;  // Which knowledge files should be activated e.g. "security-standards.md, change-approvals.md"
  cloudProvider: string;      // "aws"
  scaleMultiplier: number;    // Usually 5
  overmindDurationMs: number;
  riskCount: number;
  highRiskCount: number;
  mediumRiskCount: number;
  lowRiskCount: number;
  risks: Array<{             // Summary risk objects
    title: string;
    severity: string;
    description: string;
  }>;
  risksFull: Array<object>;   // Full risk objects from Overmind (for deep LLM analysis)
  blastRadiusNodes: number;
  blastRadiusEdges: number;
  observations: number;
  hypotheses: number;
  workflowRunUrl: string;
}
```

## Test Matrix

There are 17 test cases across 5 scenarios and 4 categories. Each scenario also has a "baseline" run (with knowledge present) to compare against.

### Categories

| Category | Purpose | How to evaluate |
|----------|---------|-----------------|
| `baseline` | Same scenarios as nightly scale-test but WITH knowledge files present | Compare risk output to nightly no-knowledge runs for the same scenario |
| `create_risk` | Knowledge should cause new or elevated risks | Check if risks reference knowledge-specific standards (encryption policy, timeout thresholds) |
| `lower_risk` | Knowledge should reduce or disprove risks | Check if risk severity decreased or risk was dismissed with knowledge-based reasoning |
| `discover` | Knowledge should surface resources not normally found | Check if blast radius includes resources mentioned in knowledge but not in Terraform graph |
| `instruct` | Knowledge should add operational context to risks | Check if risk output mentions specific contacts, processes, URLs from knowledge files |

### Test cases

**Baselines (with knowledge present):**
- `with-knowledge-sg-open` — shared_sg_open
- `with-knowledge-lambda-timeout` — lambda_timeout
- `with-knowledge-vpc-peering` — vpc_peering_change
- `with-knowledge-sns-change` — central_sns_change
- `with-knowledge-kms-orphan` — kms_orphan_simulation

**Create risk:**
- `create-risk-sg-public-exposure` — shared_sg_open: Should cite public subnet + public IP compounding from security-standards.md
- `create-risk-lambda-sqs-timeout` — lambda_timeout: Should cite 6x SQS visibility timeout rule from platform-event-pipeline.md
- `create-risk-kms-encryption-compliance` — kms_orphan_simulation: Should flag AES256 buckets as non-compliant per security-standards.md

**Lower risk:**
- `lower-risk-vpc-approved-dns` — vpc_peering_change: multi-region-design.md says DNS resolution is approved
- `lower-risk-sns-approved-hardening` — central_sns_change: platform-event-pipeline.md says Deny pattern is approved
- `lower-risk-lambda-dummy-functions` — lambda_timeout: infrastructure-guide.md says functions are dummy handlers

**Discover:**
- `discover-sns-ssm-and-publishers` — central_sns_change: Should find SSM params with stale ARN refs + Lambda publishers
- `discover-vpc-endpoints` — vpc_peering_change: Should find VPC S3 Gateway Endpoints

**Instruct:**
- `instruct-kms-security-process` — kms_orphan_simulation: Should mention sarah.chen, SEC-REVIEW Jira, VP approval
- `instruct-sg-firewall-exception` — shared_sg_open: Should mention exception form URL, mike.rodriguez, 48-hour window
- `instruct-vpc-multi-team-signoff` — vpc_peering_change: Should mention regional team contacts, #cross-region-changes
- `instruct-sns-maintenance-window` — central_sns_change: Should mention Tuesday 2-4 AM UTC, PagerDuty schedule, runbook URL

## Dashboard Pages

### 1. Knowledge Test Overview Page (`/knowledge`)

A summary page showing the latest knowledge test run results. Should include:

- **Run header:** Timestamp, workflow run link, scale multiplier
- **Category summary cards:** For each category (create_risk, lower_risk, discover, instruct), show how many tests passed/failed/pending evaluation
- **Scenario matrix:** A grid showing scenarios (rows) × categories (columns) with a status indicator (pass/fail/pending) in each cell. Clicking a cell navigates to the detail view.

### 2. Test Detail Page (`/knowledge/[testId]`)

Shows the full results for a single test case:

- **Test metadata:** Test ID, scenario, category, expected effect, relevant knowledge files
- **Risk output:** Full list of detected risks with title, severity, description
- **LLM evaluation result:** The LLM's assessment of whether knowledge had the expected effect (see below)
- **Comparison panel:** Side-by-side with the most recent nightly (no-knowledge) result for the same scenario. Highlight differences in:
  - Risk count
  - Risk severities
  - Risk titles/descriptions that are new or changed
  - Any mentions of knowledge-specific content (contact names, URLs, thresholds)

### 3. Comparison View (`/knowledge/compare/[scenario]`)

For a given scenario, shows all test results grouped together:

- The nightly no-knowledge baseline (from `/api/results` with matching scenario)
- The knowledge baseline (`with-knowledge-*`)
- All category-specific tests for that scenario

This is particularly important for the `lambda_timeout` scenario which has tests in 3 categories (create_risk, lower_risk, baseline) — showing contradictory knowledge effects side by side.

### 4. Trend View (`/knowledge/trends`)

Over time, show whether knowledge test results are stable:
- Are the same tests passing/failing consistently?
- Are risk counts and severities stable with knowledge present?
- Line charts per test case showing risk count, severity distribution over the last 30 days

## LLM Evaluation

The core evaluation logic. For each knowledge test result, use an LLM to assess whether knowledge had the expected effect. This should run when results are received (or on-demand).

### Evaluation Prompt

For each test result, send the following to the LLM:

```
You are evaluating whether Overmind Knowledge files had their expected effect on
infrastructure risk analysis. You are given:

1. The test category and expected effect
2. The risk analysis output (with knowledge present)
3. The baseline risk analysis output (without knowledge, from nightly scale-test)
4. Which knowledge files were expected to be relevant

Your job is to assess:

**For create_risk tests:**
- Did the risk output include NEW risks or ELEVATED severity compared to baseline?
- Does the risk output reference specific standards or thresholds from the knowledge?
- Score: PASS if knowledge clearly influenced the risk output, PARTIAL if some influence
  is visible, FAIL if no difference from baseline.

**For lower_risk tests:**
- Did the risk output show LOWER severity or FEWER risks compared to baseline?
- Does the risk output reference the knowledge-based justification for why the change is safe?
- Score: PASS if risk was clearly lowered/disproved, PARTIAL if severity reduced but
  risk still present, FAIL if no difference from baseline.

**For discover tests:**
- Does the risk output mention resources that are NOT in the Terraform dependency graph?
  (SSM parameters, VPC endpoints, Lambda publishers connected via env vars)
- Are these the specific resources mentioned in the knowledge files?
- Score: PASS if new resources discovered, PARTIAL if knowledge referenced but no new
  resources, FAIL if no discovery effect.

**For instruct tests:**
- Does the risk output include specific operational context from the knowledge?
  (Contact names, Slack channels, URLs, approval processes, maintenance windows)
- Check for the SPECIFIC items listed in the expected effect.
- Score: PASS if most expected items appear, PARTIAL if some appear, FAIL if none appear.

Test details:
- Test ID: {testId}
- Category: {category}
- Scenario: {scenario}
- Expected effect: {expectedEffect}
- Relevant knowledge files: {relevantKnowledge}

Risk analysis WITH knowledge:
{risks as formatted text}

Baseline risk analysis WITHOUT knowledge:
{baseline risks as formatted text, or "No baseline available" if not found}

Respond with:
- **Score:** PASS / PARTIAL / FAIL
- **Reasoning:** 2-3 sentences explaining your assessment
- **Knowledge activated:** Which knowledge files appear to have been used (based on
  content in the risk output)
- **Key evidence:** Specific quotes or references from the risk output that show
  knowledge influence (or lack thereof)
```

### Evaluation Storage

Store the LLM evaluation alongside the test result:

```typescript
interface KnowledgeEvaluation {
  testId: string;
  score: "PASS" | "PARTIAL" | "FAIL";
  reasoning: string;
  knowledgeActivated: string[];
  keyEvidence: string[];
  evaluatedAt: string;        // ISO timestamp
  baselineRunId: string | null; // The nightly run used for comparison
}
```

### Matching Baselines

To find the no-knowledge baseline for comparison:
- Query the existing `/api/results` data for the same `scenario`
- Use the most recent nightly run (these run without knowledge since `.overmind/knowledge/` was empty before this feature)
- Once knowledge files are permanently in the repo, the nightly scale-test will also have knowledge present. At that point, the "without knowledge" baselines are historical — use the last run before knowledge files were added.

## Knowledge Files Reference

These 5 files live in `.overmind/knowledge/` in the terraform-example repo:

| File | Written by | Key content for evaluation |
|------|-----------|---------------------------|
| `security-standards.md` | Security team | S3 KMS encryption requirement, EC2 public IP/subnet rules, KMS change process, sarah.chen contact |
| `platform-event-pipeline.md` | Platform team | Lambda 6x SQS timeout rule, SNS Deny hardening approved, maintenance window Tue 2-4 AM UTC, runbook URL, alex.johnson/maria.garcia contacts |
| `change-approvals.md` | Engineering manager | Firewall exception form URL, mike.rodriguez/david.kim contacts, 48-hour review window, regional team contacts (james.park, priya.sharma, thomas.mueller, wei.zhang), SEC-REVIEW Jira tickets |
| `multi-region-design.md` | Architect | VPC peering DNS approved for service discovery, SSM params contain stale ARN refs, VPC endpoints on critical path, central SNS publishers via env vars |
| `infrastructure-guide.md` | Various (wiki) | Scale-test Lambda functions are dummy handlers, env vars for Terraform edges not runtime, DLQ alarms, cost notes |

## Implementation Notes

- Use the same database/storage pattern as the existing scale test results
- The `/api/knowledge-results` endpoint should be similar to `/api/results` but with the extended schema
- The LLM evaluation can run asynchronously after results are stored — it doesn't need to block the API response
- For the comparison view, you'll need to join knowledge test results with existing scale test results by scenario name
- The trend view can reuse chart components from the existing scale test trends page (if one exists)
- Consider adding a "Re-evaluate" button on the detail page that re-runs the LLM evaluation (useful when tuning the eval prompt)
