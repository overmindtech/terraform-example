---
sidebar_position: 4
title: Knowledge Files
---

# Knowledge Files

Knowledge files give Overmind's AI investigator the institutional knowledge that experienced engineers carry in their heads — how your systems are connected, which changes are approved, what the Terraform dependency graph doesn't show, and why things are set up the way they are. When the investigator analyzes a change, it can fetch your knowledge files to make better decisions: flagging real risks, dismissing false positives, and finding resources that aren't visible in the plan.

The value runs in both directions. You teach Overmind what your team already knows — past outages, approved patterns, compliance requirements, architectural decisions — so it stops missing things your engineers would catch. Overmind tells you about things your team *doesn't* already know — non-obvious blast radius, hidden dependencies, cascading failures across resources that aren't directly connected. Over time, as you capture more of your organization's knowledge and Overmind's analysis gets more precise, this feedback loop moves you toward fewer surprises and fewer outages with every change.

## What Are Knowledge Files?

Knowledge files are Markdown documents stored in your repository that teach the AI investigator about your specific infrastructure. Each file focuses on a domain — a system, a service, a set of policies — and provides context that Overmind can't get from the Terraform plan alone.

The most effective knowledge files go beyond listing requirements. They explain *why* things are set up a certain way, document architectural patterns that span multiple resources, identify non-obvious dependencies, and describe approved change patterns so the investigator can tell the difference between an intentional change and a mistake.

**Use knowledge files for:**

- System architecture and cross-resource relationships (e.g., how your event pipeline connects SNS, SQS, and Lambda across regions)
- Approved change patterns the AI should recognize as safe (e.g., "this SNS Deny statement is approved hardening, not a risk")
- Security and compliance requirements with reasoning (e.g., why KMS encryption is required instead of AES256)
- Non-obvious dependencies that aren't in the Terraform graph (e.g., Lambda functions that publish to SNS at runtime)
- Gotchas and failure modes that experienced engineers know about (e.g., SSM parameters becoming stale when referenced resources are replaced)
- Previous outages and incident learnings (e.g., "last time someone removed a KMS key from state, we lost access to encrypted data — here's what happened and how to avoid it")
- Approval processes and change management workflows (e.g., which changes need security review, who signs off on cross-region changes, escalation paths)

**Don't use knowledge files for:**

- Change-specific notes or one-time instructions
- Secrets, credentials, or sensitive data

## Directory Structure

Knowledge files live in the `.overmind/knowledge/` directory within your repository:

```bash
your-terraform-project/
├── .overmind/
│   ├── knowledge/
│   │   ├── event-pipeline.md
│   │   ├── security-standards.md
│   │   ├── multi-region-design.md
│   │   ├── compliance/
│   │   │   ├── gdpr-requirements.md
│   │   │   └── pci-dss-controls.md
│   │   └── networking/
│   │       └── security-groups.md
│   └── signal-config.yaml
├── main.tf
└── variables.tf
```

**Discovery rules:**

- Overmind automatically discovers all `.md` files in `.overmind/knowledge/` and its subdirectories
- Subdirectories are allowed for organization but don't affect functionality
- No CLI flag is needed — discovery happens automatically during `overmind terraform plan` and `overmind changes submit-plan`
- Invalid files generate warnings but never fail the analysis

## File Format

Each knowledge file consists of YAML frontmatter followed by a Markdown body.

### Example Knowledge File

```markdown
---
name: database-encryption
description: Encryption requirements for RDS instances and DynamoDB tables, including KMS key usage, compliance controls, and common misconfiguration patterns that have caused incidents.
---

# Database Encryption Requirements

All databases storing customer data must use KMS encryption with customer-managed
keys. This is a SOC2 control — there are no exceptions, including "temporary" or
"test" databases that touch production data.

## RDS Instances

RDS instances must have `storage_encrypted = true` with an explicit `kms_key_id`
pointing to our database KMS key. The default AWS-managed key (`aws/rds`) is not
compliant because we can't control rotation or revoke access independently.

Encryption cannot be enabled on an existing unencrypted RDS instance — it requires
creating an encrypted snapshot and restoring from it. Plan for downtime.
```

For more detailed examples showing architectural context, approved patterns, and incident history, see [Example Knowledge Files](#example-knowledge-files) below.

### Frontmatter Fields

The YAML frontmatter at the top of each file must include two required fields:

| Field | Type | Required | Constraints | Description |
| --- | --- | --- | --- | --- |
| `name` | string | Yes | 1-64 chars, kebab-case | Unique identifier for the knowledge file |
| `description` | string | Yes | 1-1024 chars | Brief summary of what the knowledge file covers |

> **The `description` is the single most important line in your knowledge file.** It determines whether the AI fetches the file for a given change. When analysis begins, Overmind injects the name and description of every knowledge file into the investigator's context — the description is how the AI decides which files are relevant. If your description is vague, the file won't get fetched, and nothing else matters. Include specific service names, resource types, and architectural concepts so the AI can match the file to the right changes.

**Good description** (specific, keyword-rich):
> "How our event processing pipeline works, including the central SNS fanout, regional SQS consumers, Lambda processing, and operational procedures. Owned by the Platform Engineering team."

**Weak description** (vague, generic):
> "Event processing configuration standards"

**Name format requirements:**

- Kebab-case: lowercase letters, digits, and hyphens only
- Must start with a letter
- Must end with a letter or digit
- 1-64 characters total

**Valid names:** `event-processing-pipeline`, `k8s-limits`, `multi-region-architecture`
**Invalid names:** `AWS-S3-Security` (not lowercase), `s3-security-` (ends with hyphen), `_s3_security` (underscores)

The frontmatter `name` is the identifier used by the system. It does not need to match the filename — a file called `security-standards.md` can have the name `security-compliance-requirements`.

**Description requirements:**

- Plain text summary (no Markdown formatting in frontmatter)
- 1-1024 characters
- Should include specific service names, resource types, and architectural concepts

### Markdown Body

The body (everything after the closing `---` of the frontmatter) contains your infrastructure knowledge in Markdown format.

**Markdown features supported:**

- Headings, lists, tables
- Code blocks for configuration examples
- **Bold** and *italic* text
- Links to external documentation (URLs only — see External References below)

## How Knowledge Is Used During Change Analysis

Knowledge files are integrated into the change analysis workflow through a progressive disclosure pattern. Knowledge context is available during both hypothesis generation and hypothesis investigation, which means it influences both *what questions the AI asks* and *how it answers them*.

### 1. Metadata Injection

When change analysis begins, Overmind loads all valid knowledge files and injects their **name** and **description** into the AI's context. This allows the investigator to see what organizational knowledge is available without loading the full content of every file.

### 2. On-Demand Retrieval

When the AI determines that a hypothesis relates to a domain covered by available knowledge, it calls the `get-knowledge` tool to fetch the full Markdown content of the relevant file. This keeps the context window focused — only the knowledge that's actually relevant to the current change gets loaded.

### 3. Knowledge-Informed Analysis

Once fetched, knowledge influences the analysis in several ways:

**Identifying risks that wouldn't be found otherwise**

Your Terraform plan changes S3 bucket encryption from KMS to AES256. Without knowledge, this looks like a routine configuration change. With your security standards knowledge file, the investigator knows that AES256 uses Amazon-managed keys you can't audit or rotate, and flags it as a compliance violation.

**Disproving false-positive risks**

Your plan adds a Deny statement to an SNS topic policy. Without knowledge, this looks like it could break publishers. With your event pipeline knowledge file, the investigator recognizes the `StringNotEquals` pattern as approved security hardening that doesn't block internal services, and either reduces the risk severity or dismisses it.

**Discovering non-obvious resources**

Your plan modifies the central SNS topic. Without knowledge, the investigator only sees resources with Terraform dependency edges — the SQS subscriptions. With your architecture knowledge file, it also looks for the Lambda functions across all 4 regions that publish to the topic at runtime, and the SSM parameters that would contain stale ARNs if the topic were replaced.

**Adding operational context**

Knowledge files can include contact information, approval processes, maintenance windows, and escalation paths. When a risk is identified, this context can appear in the risk description so engineers know who to contact and what process to follow.


## Writing Effective Knowledge Files

The difference between a knowledge file that works and one that gets ignored is how it's written. These guidelines are based on observed behavior across real change analyses.

### Lead with the description

The description determines whether the file gets fetched at all. Write it like an index entry: include every specific term the AI might match against.

```yaml
# Good: specific services, resource types, and relationships
description: How our multi-region infrastructure is designed, including the VPC peering mesh, service discovery, cross-region dependencies, and design decisions.

# Weak: too generic to match specific changes
description: Multi-region infrastructure guidelines
```

### Explain why, not just what

A flat list of requirements gives the AI nothing to reason with. Explaining *why* a requirement exists lets the AI assess whether a specific change actually violates the intent.

```markdown
# Weak
- All S3 buckets must use SSE-KMS encryption

# Effective
All data at rest must be encrypted with keys we control. This is a SOC2 requirement.
For S3 buckets this means using SSE-KMS with a customer-managed key, not the default
AES256. AES256 uses Amazon-managed keys we can't audit, can't rotate on our schedule,
and can't revoke.
```

### Document approved patterns explicitly

One of the most valuable things knowledge can do is prevent false positives. When you have approved patterns that look risky on the surface, document them so the AI can recognize them.

```markdown
## SNS Topic Policy Hardening

We've been rolling out account-restriction Deny statements on SNS topic policies.
The pattern is a Deny on `sns:Publish` with `StringNotEquals` on
`aws:PrincipalAccount`. This blocks external accounts from publishing but does NOT
block our own Lambda functions or services. If you see this pattern being added,
that's approved hardening, not a risk.

What WOULD be a risk: removing Allow statements for SQS subscriptions, or using
`StringEquals` instead of `StringNotEquals` (which would invert the logic).
```

### Describe architecture the Terraform graph can't see

Terraform's dependency graph shows explicit resource references. It doesn't show runtime relationships — services that reference each other through environment variables, SDK calls, or SSM parameters. These are often the most important things for the AI to know about.

```markdown
Lambda functions across ALL 4 regions have the central topic ARN in their
environment variables and publish to it at runtime. This means changes to the
central topic's access policy don't just affect downstream SQS subscribers — they
also affect whether upstream Lambda functions can publish. The Terraform dependency
graph only shows the subscription side, not the publishing side.
```

### Format operational context as imperative actions

Operational metadata (contacts, processes, approval requirements) works best when structured as explicit required actions rather than embedded in prose.

```markdown
## When This Policy Is Violated

**Required actions for any risk involving KMS key policy changes:**
- Contact Sarah Chen (key custodian) before applying
- File SEC-REVIEW Jira ticket
- Requires sign-off from Security Engineering
- NEVER use `terraform state rm` on KMS resources — this creates orphaned keys
```

### Capture incident history and approval processes

Some of the most valuable knowledge comes from things that have gone wrong before and processes that exist because of those incidents. When the AI knows that a particular type of change caused an outage, it can flag similar changes with specific, credible warnings instead of generic risk descriptions. Similarly, documenting approval workflows means the AI can tell engineers exactly what process to follow when a risk is identified.

```markdown
## Previous Incidents

In March 2025, a KMS key was removed from Terraform state using `terraform state rm`
during a refactor. The key still existed in AWS but Terraform created a replacement.
Three S3 buckets continued using the orphaned key. When the orphaned key's deletion
schedule completed 30 days later, those buckets became permanently unreadable. Recovery
required restoring from cross-region replicas.

**Lesson:** Never use `terraform state rm` on KMS keys. Use `terraform import` to fix
state issues instead.

## Change Approval Requirements

| Change Type | Approval Required | Contact | Timeline |
|---|---|---|---|
| Security group ingress from 0.0.0.0/0 | VP of Engineering | David Kim (@david.kim) | 48 hours |
| KMS key or key policy changes | Security Engineering | Sarah Chen (@sarah.chen) | SEC-REVIEW ticket |
| Cross-region network changes | All affected regional teams | #cross-region-changes | 24 hours per team |
| SNS/SQS policy changes | Platform Engineering | #platform-ops | Tuesdays 2-4 AM UTC |
```

### Keep files focused

Each knowledge file should cover one coherent domain. When a file tries to cover too much, the most relevant information gets diluted. If you find a file growing past a few pages, consider splitting it.

**Better:** Separate files for `event-processing-pipeline`, `multi-region-architecture`, `security-compliance-requirements`
**Worse:** One file called `everything-about-our-infrastructure`

## External References

Knowledge files can reference external documentation via URLs. This is useful for linking to:

- Cloud provider documentation (AWS, GCP, Azure, Kubernetes docs)
- Internal wikis or documentation sites
- Compliance framework specifications (GDPR, PCI-DSS, SOC2)
- Terraform provider documentation

**Supported:** `https://` and `http://` URLs in Markdown links

```markdown
See the [AWS S3 encryption documentation](https://docs.aws.amazon.com/s3/encryption) for details.
```

**Not supported:** File paths or relative links to other repository files

```markdown
<!-- This won't work -->
See [detailed encryption guide](../docs/encryption.md)
```

**Rationale:** Knowledge files are processed during change analysis jobs where local file access is limited. URLs ensure referenced material can be accessed.

## Validation Rules

Overmind validates knowledge files during discovery and reports warnings for invalid files. Validation never fails the change analysis — invalid files are skipped with warnings.

**Validation checks:**

| Check | Requirement | Error Message |
| --- | --- | --- |
| Frontmatter presence | Must start with `---` | "frontmatter is required (must start with ---)" |
| Frontmatter closure | Must have closing `---` | "frontmatter closing delimiter (---) not found" |
| YAML validity | Must be valid YAML | "invalid YAML in frontmatter" |
| Unknown fields | Only `name` and `description` allowed | "only 'name' and 'description' fields are allowed" |
| Name required | `name` must be present | "name is required" |
| Name length | 1-64 characters | "name must be 64 characters or less" |
| Name format | Kebab-case | "name must use kebab-case (lowercase letters, digits, hyphens; start with letter, end with letter or digit)" |
| Description required | `description` must be present | "description is required" |
| Description length | 1-1024 characters | "description must be 1024 characters or less" |
| Duplicate names | Names must be unique | "duplicate name 'name' (already loaded from 'path')" |
| File size | Maximum 10MB | "file size exceeds maximum allowed size" |

**What happens with invalid files:**

- CLI prints a warning with the file path and reason
- The file is skipped and not included in the analysis
- Other valid knowledge files are still loaded
- Change analysis continues normally

**Example warning output:**

```bash
Warning: skipping knowledge file "aws-s3-security.md": name must use kebab-case (lowercase letters, digits, hyphens; start with letter, end with letter or digit)
```

## Managing Knowledge Files

### Organizing Multiple Files

**By system or domain:**

```
.overmind/knowledge/
├── event-processing-pipeline.md
├── multi-region-architecture.md
├── security-compliance.md
├── change-approval-process.md
└── infrastructure-quick-reference.md
```

**By domain with subdirectories:**

```
.overmind/knowledge/
├── security/
│   ├── encryption.md
│   ├── network-policies.md
│   └── access-control.md
└── architecture/
    ├── event-pipeline.md
    └── multi-region.md
```

Choose an organization scheme that matches your team's mental model. Subdirectory structure doesn't affect functionality — it's purely for human organization.

### Version Control

Knowledge files are plain text Markdown, making them ideal for version control:

- Track changes to policies and standards over time
- Review updates through pull requests
- Ensure team consensus on infrastructure knowledge
- Revert to previous versions if needed

**Recommended workflow:**

1. Create or update knowledge files in a feature branch
2. Submit a pull request for team review
3. Merge to main after approval
4. Knowledge is automatically picked up in subsequent change analyses

### Updating Knowledge Files

When you update a knowledge file:

- Changes take effect immediately in the next change analysis
- No CLI flag or configuration update needed
- The AI will use the latest version from the repository

## Example Knowledge Files

### Security and Compliance Standards

**File:** `.overmind/knowledge/security-standards.md`

```markdown
---
name: security-compliance-requirements
description: Security team's compliance requirements and policies for our AWS infrastructure. Covers encryption, network access controls, key management, and data protection standards that all infrastructure changes must comply with.
---

# Security & Compliance Requirements

Maintained by the Security Engineering team. Questions go to Sarah Chen (@sarah.chen) or #security-reviews on Slack.

## Encryption

All data at rest must be encrypted with keys we control. This is a SOC2 requirement and there are no exceptions.

For S3 buckets this means using SSE-KMS (`aws:kms`) with a customer-managed key, not the default AES256. AES256 uses Amazon-managed keys we can't audit, can't rotate on our schedule, and can't revoke. Every bucket should reference one of our KMS keys via `kms_master_key_id`. Buckets using AES256 are non-compliant even if they're "just for testing."

## Network Access

EC2 instances must not be directly reachable from the internet:

- No public IP addresses. Instances should be in private subnets. If a subnet has `map_public_ip_on_launch = true` and you're putting instances in it, that's a finding.
- SSH (port 22) and RDP (3389) must never be open to `0.0.0.0/0` in any security group. SSH access goes through SSM Session Manager.

When an instance has BOTH a public IP and an open security group, that's critical severity. Either alone is bad, together it's directly exploitable.

Be aware that we use shared security groups attached to many instances. A permissive rule on a shared SG is much worse than on a single-purpose one because the blast radius multiplies across every attached instance.

## Key Management Process

Changes to KMS keys or key policies require a SEC-REVIEW Jira ticket and sign-off from Security Engineering before deployment.

The `prevent_destroy` lifecycle rule on KMS keys doesn't protect against `terraform state rm`, which is extremely dangerous. State removal of a KMS key creates orphaned keys — existing data stays encrypted with the old key but Terraform creates a new one. If the orphaned key gets deleted, that data is gone.
```

### Multi-Region Architecture

**File:** `.overmind/knowledge/multi-region-design.md`

```markdown
---
name: multi-region-architecture
description: How our multi-region infrastructure is designed, including the VPC peering mesh, service discovery, cross-region dependencies, and design decisions. Written for engineers who need context on why things are set up this way.
---

# Multi-Region Architecture

## Regions

We operate in 4 AWS regions: us-east-1 (primary), us-west-2, eu-west-1, ap-southeast-1. us-east-1 hosts central resources (central SNS topic, central S3 bucket, central KMS key). The other regions are peers.

## VPC Peering Mesh

All 4 regions are connected via a full mesh of VPC peering connections (6 total). DNS resolution is enabled on all peering connections and this is intentional — it's required for cross-region service discovery.

If someone is enabling DNS resolution on a peering connection, that's moving towards the correct state, not introducing risk. Having DNS resolution DISABLED is actually the problem since it means service discovery is broken for that region pair.

## S3 Access Pattern

We don't use NAT gateways (cost optimization). Lambda functions and services in private subnets access S3 through VPC Gateway Endpoints. Each region has an S3 endpoint attached to its private route table.

This creates a non-obvious dependency chain: services → private route table → VPC endpoint → S3. Changes to VPC routing or peering that add/modify routes could interfere with the endpoint's prefix list routes and break S3 access.

## Central Resources in us-east-1

Three central resources live in us-east-1 and are referenced by resources in all regions:

1. **Central SNS topic** — all SQS queues subscribe, all Lambda functions publish
2. **Central S3 bucket** — referenced by Lambda function environment variables
3. **Central KMS key** — multi-region key used for encryption

Changes to any central resource potentially affect all 4 regions. The central SNS topic has the widest blast radius because it has both subscriber edges (visible in Terraform) and publisher edges (Lambda env vars, NOT visible as Terraform dependencies).

## Configuration Distribution via SSM

Runtime configuration is distributed via SSM Parameter Store. Parameters under `/ovm-scale/` contain references to resource ARNs and URLs. If a referenced resource is replaced (changing its ARN), the SSM parameters become stale. The parameters won't show up in the Terraform plan diff but they'll contain invalid ARNs — the failure only shows up at runtime.
```

## Troubleshooting

### Knowledge file not being used

**Possible causes:**

1. **Description doesn't match the change**
   - The AI decides whether to fetch a file based on the description. If the description doesn't mention the service or resource type being changed, the file won't be fetched. Make descriptions keyword-rich and specific.

2. **File not in the correct directory**
   - Must be in `.overmind/knowledge/` or a subdirectory
   - Must have `.md` extension

3. **Validation errors**
   - Check CLI output for warnings during `terraform plan`
   - Verify frontmatter format (starts and ends with `---`)
   - Ensure name and description meet requirements

4. **Not relevant to the change**
   - The AI only fetches knowledge when a hypothesis relates to that domain
   - If your change doesn't affect the area covered by the knowledge file, it won't be consulted

### Duplicate name warnings

Each knowledge file must have a unique `name` in its frontmatter. If two files share a name, the first one (alphabetically by file path) is loaded and the second is skipped.

**Solution:** Ensure each file has a unique `name` field, regardless of filename or directory location.

## Feature Availability

Knowledge file support is controlled by the `knowledge-in-investigation` feature flag. This feature is progressively rolled out and may not be available in all accounts.

When the feature is not enabled:

- Knowledge files are still discovered and validated
- Warnings are still shown for invalid files
- Knowledge is not injected into the AI investigator's context
- Change analysis proceeds without knowledge-informed investigation

Contact Overmind support if you'd like to enable knowledge files for your organization.

## Related Documentation

- [Change Analysis Process](/creating-changes/change_analysis) - Overview of the change analysis workflow
- [CLI Configuration](/cli/configuration) - Configuration file discovery and project structure
- [Domain Glossary](/misc/glossary#knowledge) - Technical definition of Knowledge in Overmind's domain model
