---
name: security-compliance-requirements
description: Security team's compliance requirements and policies for our AWS infrastructure. Covers encryption, network access controls, key management, and data protection standards that all infrastructure changes must comply with.
---

# Security & Compliance Requirements

Maintained by the Security Engineering team. Questions go to Sarah Chen (@sarah.chen, sarah.chen@acme.com) or #security-reviews on Slack.

## Encryption

All data at rest must be encrypted with keys we control. This is a SOC2 requirement and there are no exceptions.

For S3 buckets this means using SSE-KMS (`aws:kms`) with a customer-managed key, not the default AES256. AES256 uses Amazon-managed keys we can't audit, can't rotate on our schedule, and can't revoke. Every bucket should reference one of our KMS keys via `kms_master_key_id`. Buckets using AES256 are non-compliant even if they're "just for testing."

EBS volumes must have `encrypted = true` and should use our central KMS key where possible. The default `aws/ebs` key is acceptable for non-sensitive workloads but not preferred.

KMS keys themselves are high-value assets. Key policies must follow least-privilege - only grant the specific service principals (s3.amazonaws.com, ec2.amazonaws.com, etc.) that actually need access. Removing service principals from a key policy can break encryption/decryption for resources using that key, so be careful.

SSM SecureString parameters are encrypted with KMS too. Changes to KMS key access can cascade to parameter decryption failures which are hard to debug since the error just shows up as an access denied in the application.

## Network Access

EC2 instances must not be directly reachable from the internet. This means:

- No public IP addresses. Instances should be in private subnets. If a subnet has `map_public_ip_on_launch = true` and you're putting instances in it, that's a finding.
- SSH (port 22) and RDP (3389) must never be open to `0.0.0.0/0` in any security group. SSH access goes through SSM Session Manager.
- Any inbound rule from `0.0.0.0/0` needs a firewall exception (see change management process).

When an instance has BOTH a public IP and an open security group, that's critical severity. Either alone is bad, together it's directly exploitable.

Be aware that we use shared security groups attached to many instances. A permissive rule on a shared SG is much worse than on a single-purpose one because the blast radius multiplies across every attached instance.

## Key Management Process

Changes to KMS keys or key policies require a SEC-REVIEW Jira ticket and sign-off from Security Engineering before deployment. This includes policy changes, deletion scheduling, rotation settings, alias changes, and grants.

The `prevent_destroy` lifecycle rule on KMS keys is necessary but doesn't protect against `terraform state rm`, which is extremely dangerous. State removal of a KMS key creates orphaned keys - existing data stays encrypted with the old key but Terraform creates a new one. If the orphaned key gets deleted, that data is gone.

If a KMS change is causing production issues (services can't encrypt/decrypt), page the security on-call via #security-incidents Slack channel or PagerDuty Security Engineering escalation.
