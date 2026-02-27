---
name: engineering-change-process
description: How infrastructure changes get reviewed and approved across the engineering org. Covers approval workflows, team contacts, review timelines, and escalation paths for different types of changes.
---

# Engineering Change Process

## General Rule

Most infrastructure changes go through normal PR review. But certain categories of changes have additional approval requirements because they affect shared resources, security boundaries, or multiple teams.

## Network Changes

Security group changes that modify inbound rules need Network team review.

- Contact: Mike Rodriguez (@mike.rodriguez), #network-ops
- Standard changes (VPC-internal CIDR adjustments): 24-hour review window
- Internet-facing changes (any rule with `0.0.0.0/0`): 48-hour window + VP approval
- Firewall exception form: https://internal.acme.com/network/exceptions (include SG ID, port range, protocol, business justification)
- VP of Engineering for internet-facing approvals: David Kim (@david.kim)

For shared security groups attached to many resources, the network team wants to see the full blast radius (how many instances affected) before approving.

Cross-region network changes are more complex because they span team boundaries. VPC peering modifications, cross-region routing changes, and anything that affects the network mesh requires sign-off from multiple teams:

1. **Network team** - routing and peering config
2. **Security team** - cross-boundary access implications
3. **Regional application teams** - teams whose workloads are in affected regions

Coordinate in #cross-region-changes. Each affected team gets 24 hours to review.

## Regional Team Contacts

| Region | Lead | Channel |
|--------|------|---------|
| us-east-1 | James Park (@james.park) | #team-us-east |
| us-west-2 | Priya Sharma (@priya.sharma) | #team-us-west |
| eu-west-1 | Thomas Mueller (@thomas.mueller) | #team-eu |
| ap-southeast-1 | Wei Zhang (@wei.zhang) | #team-apac |

## Encryption & Key Changes

KMS key and key policy changes require a SEC-REVIEW Jira ticket and Security Engineering approval before deployment. Key deletion scheduling requires VP-level approval. See the Security team's standards for details.

Contact: Sarah Chen (@sarah.chen), #security-reviews

## Event Bus Changes

SNS topic policies, SQS queue configs, subscription changes - coordinate with Platform Engineering.

- Maintenance window: Tuesdays 2-4 AM UTC
- On-call: PagerDuty "Platform-Primary"
- Contact: #platform-ops

## Emergency Changes

If something is actively broken in production and you need to skip the review process:

1. Make the change
2. Post in the relevant team channel with "EMERGENCY CHANGE" prefix
3. File a retroactive review within 24 hours
4. Include incident timeline and justification

## What Doesn't Need Special Approval

- Tagging changes
- Log retention adjustments
- Scaling changes within existing resource types (adjusting counts, not creating new resource types)
- Lambda code deployments (covered by CI/CD pipeline)
