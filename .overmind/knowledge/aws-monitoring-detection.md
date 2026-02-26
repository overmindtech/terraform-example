---
name: aws-monitoring-detection
description: AWS Well-Architected best practices for monitoring, logging, and threat detection, including CloudTrail, CloudWatch alarms, VPC Flow Logs, GuardDuty, AWS Config rules, access logging, and billing alarms. Relevant when changes affect observability, audit trails, or security detection capabilities.
---

# Monitoring, Logging, and Threat Detection

The [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) is a collection of best practices published by AWS, organized into six pillars: Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, and Sustainability. When a Terraform change conflicts with a best practice described below, raise a risk. Each risk item includes a severity (High, Medium, or Low) and the originating best practice ID. Use the indicated severity and reference the best practice ID in the risk description.

This document draws from the Security Pillar (SEC4), Operational Excellence Pillar (OPS4), Reliability Pillar (REL6), and Cost Optimization Pillar (COST3).

## CloudTrail and Audit Logging

CloudTrail should be enabled in all regions and configured to deliver logs to a centralized S3 bucket with appropriate retention. CloudTrail is the primary audit log for all AWS API activity and is essential for security investigations, compliance, and incident response.

**Risks to flag:**

- CloudTrail being disabled or its trail being deleted. This eliminates the audit trail for all API activity. (High — SEC04-BP01)
- CloudTrail logs stored without integrity validation enabled (`enable_log_file_validation`). Without this, log tampering cannot be detected. (Medium — SEC04-BP01)
- CloudTrail log S3 bucket with overly permissive access policies. Logs should be accessible only to security and audit teams. (High — SEC04-BP01)
- CloudTrail logs without encryption using a customer-managed KMS key. (Low — SEC04-BP01)
- CloudTrail logs retained indefinitely without lifecycle policies, or deleted too quickly before compliance retention periods are met. (Low — SEC04-BP01)

## Threat Detection Services

GuardDuty, AWS Config, and Security Hub should be enabled across all accounts and regions. These services provide continuous monitoring for security threats, resource compliance, and best practice adherence.

**Risks to flag:**

- GuardDuty being disabled or suspended. GuardDuty provides threat detection for IAM credential misuse, cryptocurrency mining, data exfiltration, and other threats. (High — SEC04-BP03)
- AWS Config being disabled. Config tracks resource configuration history and enables compliance rules. (Medium — SEC04-BP04)
- Security Hub being disabled. Security Hub aggregates findings from multiple security services and runs compliance checks. (Medium — SEC04-BP03)
- AWS Config rules being removed or disabled, reducing the detective controls in the environment. (Medium — SEC04-BP04)

## VPC Flow Logs and Network Monitoring

VPC Flow Logs capture network traffic metadata (source, destination, ports, action) and are essential for network troubleshooting, security analysis, and compliance. They should be enabled on all VPCs used by production workloads.

**Risks to flag:**

- VPCs without Flow Logs enabled. (Medium — SEC04-BP01)
- Flow Logs configured to capture only accepted traffic (`ACCEPT`). Rejected traffic is equally important for detecting probing and unauthorized access attempts. Both should be captured. (Low — SEC04-BP01)
- Flow Logs with short retention periods that don't meet compliance or investigation needs. (Low — SEC04-BP01)

## CloudWatch Alarms and Metrics

CloudWatch alarms should be configured for key operational and security metrics. Alarms should trigger notifications and, where appropriate, automated remediation actions.

**Risks to flag:**

- Workloads in production with no CloudWatch alarms configured. (High — REL06-BP03)
- Alarm thresholds set too high (insensitive) or too low (alert fatigue). Both scenarios reduce the effectiveness of monitoring. (Medium — REL06-BP03)
- Alarms without SNS notification targets — nobody gets notified when something goes wrong. (Medium — REL06-BP03)
- Auto scaling groups without alarms for scaling activity, errors, or capacity changes. (Low — REL06-BP04)
- No billing alarms or budgets configured to detect unexpected cost spikes. (Medium — COST03-BP05)

## Application and Workload Observability

Workloads should implement comprehensive telemetry: application-level metrics, distributed tracing, and real user monitoring. Observability should extend to all dependencies, not just the application's own components.

**Risks to flag:**

- No application-level logging or metrics beyond default AWS service metrics. (Medium — OPS04-BP02)
- Distributed tracing not implemented for microservices architectures, making it difficult to diagnose latency issues and failures across service boundaries. (Low — OPS04-BP05)
- External dependencies not monitored — workloads that depend on third-party services or cross-account resources without health checks or monitoring. (Low — OPS04-BP04)

**What good looks like:**

- CloudTrail enabled in all regions with log file validation and centralized logging
- GuardDuty, Config, and Security Hub enabled across all accounts
- VPC Flow Logs enabled on all production VPCs
- CloudWatch alarms for key metrics with appropriate thresholds and notification targets
- Billing alarms and budget alerts configured
- Distributed tracing with X-Ray or equivalent for microservices
- Centralized log aggregation for correlation and investigation

## AWS Documentation References

### Pillar Documentation

- [Security Pillar — AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
- [Operational Excellence Pillar — AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/welcome.html)
- [Reliability Pillar — AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/welcome.html)
- [Cost Optimization Pillar — AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/welcome.html)

### Source Questions

- [SEC 4 — How do you detect and investigate security events?](https://docs.aws.amazon.com/wellarchitected/latest/framework/sec-04.html)
- [OPS 4 — How do you implement observability in your workload?](https://docs.aws.amazon.com/wellarchitected/latest/framework/ops-04.html)
- [REL 6 — How do you monitor workload resources?](https://docs.aws.amazon.com/wellarchitected/latest/framework/rel-06.html)
- [COST 3 — How do you monitor your cost and usage?](https://docs.aws.amazon.com/wellarchitected/latest/framework/cost-03.html)
