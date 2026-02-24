---
name: event-processing-pipeline
description: How our event processing pipeline works, including the central SNS fanout, regional SQS consumers, Lambda processing, and operational procedures. Owned by the Platform Engineering team.
---

# Event Processing Pipeline

Owned by Platform Engineering. Leads: Alex Johnson (@alex.johnson, US) and Maria Garcia (@maria.garcia, EU).

## Architecture

We have a central SNS topic in us-east-1 that fans out events to SQS queues in all 4 regions. Think of it as a hub-and-spoke pattern. The central topic is the single point of entry and the regional queues are where processing happens.

The flow is:

1. Lambda functions (and other services) publish events to the central SNS topic
2. Central topic fans out to SQS queues in us-east-1, us-west-2, eu-west-1, ap-southeast-1
3. Consumers read from their regional SQS queue and process events

The publishing side is important and easy to miss. Lambda functions across ALL 4 regions have the central topic ARN in their environment variables (`CENTRAL_SNS_TOPIC`) and publish to it using the SDK at runtime. This means changes to the central topic's access policy don't just affect the downstream SQS subscribers - they also affect whether the upstream Lambda functions can publish. The Terraform dependency graph only shows the subscription side, not the publishing side.

## Lambda-SQS Integration

Our Lambda functions process messages from SQS queues. The critical thing to know is that Lambda timeout must be longer than the SQS visibility timeout, otherwise you get duplicate message processing. AWS recommends at least 6x the visibility timeout.

Our SQS queues use 30-second visibility timeout, so ideally Lambda functions should have at least 180 seconds timeout. If the timeout is shorter than the visibility timeout (30 seconds), messages become visible again while still being processed, which leads to duplicates and eventually messages ending up in the DLQ.

Memory matters too - 128MB is tight for anything doing real work, but fine for lightweight handlers.

## Operational Procedures

The event bus is a production-critical system. Changes need coordination:

- **Maintenance window:** Tuesdays 2:00-4:00 AM UTC. This is when event bus changes should be deployed.
- **On-call:** Check PagerDuty schedule "Platform-Primary" before deploying. Notify them in #platform-ops.
- **If things break:** SQS retains messages for 4 days so there's a buffer. Check the runbook at https://runbooks.acme.com/event-bus-recovery. DLQ alarms in CloudWatch will fire if messages are failing - the ops team has PagerDuty integration on those.

## SNS Topic Policy Hardening

We've been rolling out account-restriction Deny statements on SNS topic policies. The pattern is a Deny on `sns:Publish` with `StringNotEquals` on `aws:PrincipalAccount`. This blocks external accounts from publishing but does NOT block our own Lambda functions or services. If you see this pattern being added to a topic policy, that's approved hardening, not a risk.

What WOULD be a risk: removing the Allow statements for SQS subscriptions, or adding a Deny on `sns:Subscribe` which could break cross-region fanout. Also watch out for someone accidentally using `StringEquals` instead of `StringNotEquals` in the condition - that would invert the logic and block our own account.
