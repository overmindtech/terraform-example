---
name: aws-data-protection
description: AWS Well-Architected best practices for data protection, including encryption at rest with KMS, S3 bucket encryption and policies, RDS and EBS encryption, encryption in transit with TLS and ACM certificates, and data classification through tagging. Relevant when changes affect how data is encrypted, stored, or transmitted.
---

# Data Protection

The [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) is a collection of best practices published by AWS, organized into six pillars: Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, and Sustainability. When a Terraform change conflicts with a best practice described below, raise a risk. Each risk item includes a severity (High, Medium, or Low) and the originating best practice ID. Use the indicated severity and reference the best practice ID in the risk description.

This document draws from the Security Pillar (SEC7, SEC8, SEC9).

## Data Classification

Data should be classified by sensitivity level (public, internal, confidential, restricted) and tagged accordingly. Protection controls should match the classification — applying the same level of protection to all data either over-spends on low-sensitivity data or under-protects high-sensitivity data.

**Risks to flag:**

- Data stores (S3 buckets, RDS instances, DynamoDB tables) without tags indicating data classification or sensitivity level. (Low — SEC07-BP01)
- Storing data with different classification levels in the same location without appropriate access controls separating them. (Medium — SEC08-BP04)

## Encryption at Rest

All data at rest should be encrypted. AWS services that support encryption should have it enabled by default. Customer-managed KMS keys (CMKs) are preferred over AWS-managed keys for sensitive data because they provide control over key rotation, access policies, and revocation.

**Risks to flag:**

- S3 buckets without server-side encryption enabled, or using AES256 (SSE-S3) instead of SSE-KMS for sensitive data. SSE-S3 uses Amazon-managed keys that cannot be independently audited or revoked. (Medium — SEC08-BP02)
- RDS instances with `storage_encrypted = false`. Encryption cannot be enabled on an existing unencrypted instance — it requires creating an encrypted snapshot and restoring from it. (High — SEC08-BP02)
- EBS volumes created without encryption enabled. (Medium — SEC08-BP02)
- DynamoDB tables without encryption using a customer-managed key when required by compliance. (Low — SEC08-BP02)
- Using a single KMS key for all data regardless of type, usage, or classification. Different data classes should use different keys to limit blast radius. (Medium — SEC08-BP02)
- KMS key policies with overly broad permissions granting access to more principals than necessary. (High — SEC08-BP01)
- KMS keys being deleted or scheduled for deletion — this can permanently render encrypted data unrecoverable. (High — SEC08-BP01)
- S3 buckets with public access enabled (`block_public_access` not configured) when they contain sensitive data. (High — SEC08-BP03)

## Encryption in Transit

All network communications should use TLS. Load balancer listeners should use HTTPS, not HTTP. Certificates should be managed through ACM for automatic renewal. Deprecated TLS versions and weak cipher suites should not be used.

**Risks to flag:**

- Load balancer listeners configured for HTTP (port 80) without redirection to HTTPS (port 443). Public-facing endpoints must enforce TLS. (High — SEC09-BP02)
- TLS security policies on load balancers or CloudFront distributions using deprecated SSL/TLS versions (SSLv3, TLS 1.0, TLS 1.1) or weak cipher suites. (Medium — SEC09-BP02)
- Self-signed certificates used for public-facing resources instead of certificates from ACM or a trusted CA. (Medium — SEC09-BP01)
- ACM certificates approaching expiration without auto-renewal configured. (Medium — SEC09-BP01)
- Unencrypted connections between internal services when TLS is feasible (e.g., Redis without in-transit encryption, RDS without SSL enforcement). (Low — SEC09-BP02)

## Key Management

KMS keys should follow least-privilege access. Key policies should restrict who can administer, use, and grant access to keys. Human operators should not have access to unencrypted key material. Key rotation should be automated.

**What good looks like:**

- Customer-managed KMS keys with restrictive key policies
- Automatic key rotation enabled on KMS keys
- Separate keys for different data classifications
- KMS key usage monitored via CloudTrail
- No human access to unencrypted key material
- S3 bucket policies requiring `aws:SecureTransport` for all requests

## AWS Documentation References

### Pillar Documentation

- [Security Pillar — AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)

### Source Questions

- [SEC 7 — How do you classify your data?](https://docs.aws.amazon.com/wellarchitected/latest/framework/sec-07.html)
- [SEC 8 — How do you protect your data at rest?](https://docs.aws.amazon.com/wellarchitected/latest/framework/sec-08.html)
- [SEC 9 — How do you protect your data in transit?](https://docs.aws.amazon.com/wellarchitected/latest/framework/sec-09.html)
