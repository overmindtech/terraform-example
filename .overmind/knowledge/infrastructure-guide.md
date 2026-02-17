---
name: Infrastructure Quick Reference
description: Practical notes about our infrastructure setup, common patterns, gotchas, and things that aren't obvious from reading the Terraform code. Updated by various team members as they learn things the hard way.
---

# Infrastructure Quick Reference

This is a collection of things people have learned about our infrastructure that aren't obvious from the code. If you discover something non-obvious, add it here.

## Shared Resources (Watch Out)

We have several shared resources where one change affects many downstream things:

- **Shared security groups** - tagged "high-fanout-testing", attached to ALL EC2 instances in a region. Changing a rule on these SGs affects every instance. This is by design for our testing but makes any SG rule change high-impact.
- **Shared Lambda execution role** - all Lambda functions in a region share one IAM role. Policy changes cascade to every function.
- **Central SNS topic** - every SQS queue in every region subscribes. Every Lambda function publishes. Changing its policy is basically touching everything.

## The Scale Test Environment

The ovm-scale resources are for Overmind's own testing infrastructure. Some things to know:

- EC2 instances are created in a stopped state. They're there for relationship density, not for running anything.
- Lambda functions are dummy Node.js handlers that just log and return 200. They don't do real message processing despite having SQS references in their env vars. The environment variables reference SNS topics and SQS queues to create Terraform edges, not for actual runtime use.
- S3 buckets have 1-day lifecycle expiration to prevent accidental cost accumulation.
- SSM parameters store config JSON with ARNs and IDs of other resources - this creates indirect relationships that aren't Terraform edges.

## Subnets and Routing

There are public subnets (with IGW route) and private subnets (no internet access). EC2 instances end up in public subnets because we don't have NAT gateways. In a real setup you'd want them in private subnets but for testing this saves ~$100/month per region on NAT.

The private subnets are used for Lambda VPC attachments. S3 access from private subnets goes through VPC Gateway Endpoints, not the internet.

## IAM Patterns

Lambda execution roles have cross-service policies granting access to SQS, SNS, S3, SSM, and CloudWatch Logs. The wildcard patterns use `ovm-scale-*` resource ARNs so they're scoped to our namespace but not to specific resources.

The high-fanout shared Lambda role uses the first cross-service policy (`cross_service[0]`). This means changing that specific policy instance affects all Lambda functions.

## Dead Letter Queues

Every 3rd SQS queue has a DLQ associated. If message processing breaks (e.g. Lambda timeout too low, SQS permissions changed), messages end up in DLQs. The ops team has CloudWatch alarms on DLQ depth that page via PagerDuty, so breaking message flow will trigger incidents even if nobody notices immediately.

## Cost Notes

Most resources are cheap or free when idle. The main cost drivers are:
- EC2 instances (even stopped, EBS volumes cost money) - ~$0.08/GB/month for gp3
- VPC peering data transfer if anything actually sends traffic cross-region
- Lambda invocations if event source mappings are accidentally enabled
- KMS key charges ($1/month per key)
