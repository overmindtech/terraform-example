---
name: aws-compute-configuration
description: AWS Well-Architected best practices for compute resources, including EC2 instance types and hardening, Lambda configuration, ECS/EKS, auto scaling groups, right-sizing, and Graviton adoption. Relevant when changes affect compute resource selection, sizing, or security configuration.
---

# Compute Configuration

The [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) is a collection of best practices published by AWS, organized into six pillars: Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, and Sustainability. When a Terraform change conflicts with a best practice described below, raise a risk. Each risk item includes a severity (High, Medium, or Low) and the originating best practice ID. Use the indicated severity and reference the best practice ID in the risk description.

This document draws from the Security Pillar (SEC6), Performance Efficiency Pillar (PERF2), Sustainability Pillar (SUS5), and Cost Optimization Pillar (COST6).

## Instance Type Selection and Right-Sizing

Compute resources should be selected based on workload characteristics (CPU, memory, I/O, networking). Using only one instance family for all workloads is an anti-pattern. Instance types should be regularly re-evaluated as AWS releases new generations with better performance-per-cost. Graviton (ARM) instances offer better price-performance and energy efficiency for many workloads.

**Risks to flag:**

- Using previous-generation instance types (e.g., m4, c4, t2) when current-generation equivalents (m7g, c7g, t3) offer better performance at lower cost. (Low — PERF02-BP04, SUS05-BP02)
- Over-provisioned instances that are significantly larger than the workload requires. Check AWS Compute Optimizer or Cost Explorer recommendations. (Medium — PERF02-BP04, SUS05-BP01)
- Using only x86 instance types without evaluating Graviton (ARM) instances, which offer up to 40% better price-performance for many workloads. (Low — SUS05-BP02)
- Using compute-optimized instances for memory-intensive workloads, or vice versa. Instance family should match workload characteristics. (Low — SUS05-BP02)
- Auto scaling groups with only a single instance type specified. Use mixed instance policies with multiple types for better availability and cost. (Low — SUS05-BP02)
- Resources with low utilization that are never reviewed for resizing. (Medium — SUS05-BP01)

## Managed Services vs. Self-Managed

Where possible, use managed services (RDS, ECS Fargate, Lambda) instead of self-managed EC2 instances to reduce operational overhead and security scope. Running databases, message brokers, or container orchestration on EC2 when managed alternatives exist increases the security surface and operational burden.

**Risks to flag:**

- Self-managed databases on EC2 instances when Amazon RDS, Aurora, or DynamoDB could be used. (Low — SEC06-BP05, SUS05-BP03)
- EC2 instances with low utilization running applications that could be serverless (Lambda) or containerized (Fargate). (Low — SUS05-BP03)

## Compute Hardening

EC2 instances should be launched from hardened, regularly updated AMIs. Unnecessary software packages should be removed. Interactive SSH/RDP access should be replaced with AWS Systems Manager Session Manager. Software integrity should be verified through signatures.

**Risks to flag:**

- EC2 instances using old or unpatched AMIs. Images should be regularly rebuilt and updated. (Medium — SEC06-BP02)
- Security groups allowing SSH (port 22) or RDP (port 3389) access from `0.0.0.0/0`. Use Systems Manager Session Manager instead. (High — SEC06-BP03)
- EC2 instances without IAM instance profiles (no IAM role attached), suggesting hardcoded credentials may be in use. (Medium — SEC06-BP03)
- Lambda functions using deprecated runtimes that no longer receive security patches. (Medium — SEC06-BP01)

## Auto Scaling

Compute resources should scale dynamically with demand rather than being statically provisioned. Auto scaling groups should have appropriate minimum, maximum, and desired capacity settings. Scaling should be based on meaningful metrics (CPU, request count, queue depth) rather than arbitrary schedules alone.

**Risks to flag:**

- Auto scaling groups with min, max, and desired all set to the same value, effectively disabling scaling. (Medium — PERF02-BP05)
- No auto scaling configured for workloads with variable demand, relying on manually sized static fleets. (Medium — PERF02-BP05, SUS02-BP01)
- Leaving increased capacity in place after a scaling event without scaling back down. (Low — PERF02-BP05)

**What good looks like:**

- Dynamic auto scaling based on application-level metrics
- Mixed instance type policies in ASGs for cost and availability
- Graviton instances evaluated for all new workloads
- Hardened, regularly updated AMIs via EC2 Image Builder
- Session Manager used instead of SSH/RDP
- Lambda functions on supported, current runtimes

## AWS Documentation References

### Pillar Documentation

- [Security Pillar — AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
- [Performance Efficiency Pillar — AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/performance-efficiency-pillar/welcome.html)
- [Sustainability Pillar — AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/sustainability-pillar/sustainability-pillar.html)
- [Cost Optimization Pillar — AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/welcome.html)

### Source Questions

- [SEC 6 — How do you protect your compute resources?](https://docs.aws.amazon.com/wellarchitected/latest/framework/sec-06.html)
- [PERF 2 — How do you select and use compute resources in your workload?](https://docs.aws.amazon.com/wellarchitected/latest/framework/perf-02.html)
- [SUS 5 — How do you select and use cloud hardware and services to support your sustainability goals?](https://docs.aws.amazon.com/wellarchitected/latest/framework/sus-05.html)
- [COST 6 — How do you meet cost targets when you select resource type, size and number?](https://docs.aws.amazon.com/wellarchitected/latest/framework/cost-06.html)
