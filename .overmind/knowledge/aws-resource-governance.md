---
name: aws-resource-governance
description: AWS Well-Architected best practices for resource governance and lifecycle management, including tagging standards, resource decommissioning, TTL policies, service quotas, budgets, Service Control Policies, and infrastructure-as-code patterns. Relevant when changes affect resource tagging, lifecycle controls, or organizational guardrails.
---

# Resource Governance and Lifecycle Management

The [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) is a collection of best practices published by AWS, organized into six pillars: Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, and Sustainability. When a Terraform change conflicts with a best practice described below, raise a risk. Each risk item includes a severity (High, Medium, or Low) and the originating best practice ID. Use the indicated severity and reference the best practice ID in the risk description.

This document draws from the Cost Optimization Pillar (COST2, COST4, COST9), Sustainability Pillar (SUS2), Reliability Pillar (REL1), and Operational Excellence Pillar (OPS5).

## Tagging Standards

All resources should be tagged with a consistent set of mandatory tags for cost allocation, ownership, environment identification, and lifecycle management. Tags enable cost attribution, compliance enforcement, and automated governance policies.

**Risks to flag:**

- Resources created without mandatory tags (e.g., `Environment`, `Owner`, `Project`, `CostCenter`). Untagged resources cannot be attributed to teams or projects for cost management. (Medium — COST04-BP01)
- Inconsistent tag key naming (e.g., `env` vs `Environment` vs `environment`) across resources. Tag keys should follow a documented standard. (Low — COST04-BP01)
- Resources without an `Environment` tag distinguishing production from non-production. This is critical for applying appropriate security and operational controls. (Medium — COST04-BP01)

## Resource Decommissioning and Lifecycle

Resources that are no longer needed should be identified and decommissioned. Unused resources (idle EC2 instances, unattached EBS volumes, unused Elastic IPs, empty security groups, stale snapshots) incur unnecessary cost and increase the attack surface.

**Risks to flag:**

- EBS volumes in an `available` (unattached) state — these incur cost but are not being used. (Low — COST04-BP02)
- Elastic IP addresses not associated with a running instance — these incur hourly charges when unattached. (Low — COST04-BP02)
- Idle load balancers with no registered targets or zero traffic. (Low — COST04-BP02)
- Resources without TTL or expiration tags/policies, especially in development and test environments. Non-production resources should have automated cleanup. (Medium — SUS02-BP03)
- Unused or redundant assets that have not been analyzed for removal. (Low — SUS02-BP03)

## Service Quotas

AWS service quotas (formerly limits) should be proactively monitored and managed. Running into a quota limit during a scaling event or incident can prevent recovery. Quotas should account for failover scenarios — if one AZ is lost, can the remaining AZs handle the load within their quotas?

**Risks to flag:**

- Deploying workloads without understanding the applicable service quotas and constraints. (Medium — REL01-BP01)
- No monitoring of service quota utilization. Quotas can be hit silently, causing failures. (Medium — REL01-BP04)
- Not maintaining a sufficient gap between current usage and quota limits to accommodate failover scenarios. If an AZ fails, the remaining AZs may need to absorb the load. (Medium — REL01-BP06)
- Assuming quotas are the same across all regions. Default quotas can vary by region. (Low — REL01-BP02)
- No automated process to request quota increases before they become urgent. (Low — REL01-BP05)

## Service Control Policies and Guardrails

SCPs should enforce organizational guardrails — restricting which services, regions, and actions are available to member accounts. Budgets should be set with alerts for unexpected spending.

**Risks to flag:**

- Member accounts in AWS Organizations without SCPs restricting permitted services and regions. (Medium — COST02-BP01)
- No AWS Budgets or billing alerts configured to detect unexpected cost increases. (Medium — COST02-BP03)
- SCPs being removed or weakened, reducing the guardrail boundary for member accounts. (High — COST02-BP01)

## Infrastructure as Code

All infrastructure should be defined as code, stored in version control, tested in CI/CD pipelines, and deployed through automation. Manual changes through the console (click-ops) lead to configuration drift, are error-prone, and cannot be audited or rolled back reliably.

**Risks to flag:**

- Infrastructure not managed through Terraform, CloudFormation, or another IaC tool. Manual provisioning cannot be reliably reproduced or audited. (Medium — OPS05-BP01)
- Changes deployed directly to production without passing through testing environments. (Medium — OPS05-BP02)
- Configuration changes made manually through the console instead of through code. This leads to drift between the actual state and the declared state. (Medium — OPS05-BP03)
- Deploying large, infrequent changes instead of small, frequent, reversible changes. Large changes are harder to debug, review, and roll back. (Low — OPS05-BP09)

## Demand Management and Scaling

Resources should scale with demand rather than being statically over-provisioned. Auto scaling, scheduled scaling, and queue-based buffering should be used to match supply to demand. Over-provisioned static resources waste cost and energy.

**What good looks like:**

- Mandatory tagging policies enforced through SCPs or AWS Config rules
- Automated identification and cleanup of unused resources
- Service quotas monitored with CloudWatch and proactively increased
- AWS Budgets with alerts for cost anomalies
- All infrastructure defined in Terraform/CloudFormation and deployed through CI/CD
- Small, frequent, reversible deployments
- Non-production resources with automated TTL or cleanup policies

## AWS Documentation References

### Pillar Documentation

- [Cost Optimization Pillar — AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/welcome.html)
- [Sustainability Pillar — AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/sustainability-pillar/sustainability-pillar.html)
- [Reliability Pillar — AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/welcome.html)
- [Operational Excellence Pillar — AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/welcome.html)

### Source Questions

- [COST 2 — How do you govern usage?](https://docs.aws.amazon.com/wellarchitected/latest/framework/cost-02.html)
- [COST 4 — How do you decommission resources?](https://docs.aws.amazon.com/wellarchitected/latest/framework/cost-04.html)
- [COST 9 — How do you manage demand, and supply resources?](https://docs.aws.amazon.com/wellarchitected/latest/framework/cost-09.html)
- [SUS 2 — How do you align cloud resources to your demand?](https://docs.aws.amazon.com/wellarchitected/latest/framework/sus-02.html)
- [REL 1 — How do you manage Service Quotas and constraints?](https://docs.aws.amazon.com/wellarchitected/latest/framework/rel-01.html)
- [OPS 5 — How do you reduce defects, ease remediation, and improve flow into production?](https://docs.aws.amazon.com/wellarchitected/latest/framework/ops-05.html)
