---
name: aws-iam-access-control
description: AWS Well-Architected best practices for identity and access management, including IAM roles, policies, users, least-privilege permissions, MFA, cross-account access, multi-account strategy, SCPs, and AWS Organizations. Relevant when changes affect who or what can access AWS resources and how access boundaries are defined.
---

# IAM and Access Control

The [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) is a collection of best practices published by AWS, organized into six pillars: Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, and Sustainability. When a Terraform change conflicts with a best practice described below, raise a risk. Each risk item includes a severity (High, Medium, or Low) and the originating best practice ID. Use the indicated severity and reference the best practice ID in the risk description.

This document draws from the Security Pillar (SEC1, SEC2, SEC3).

## Multi-Account Strategy and Isolation

Workloads and environments (production, development, test) should be separated into distinct AWS accounts. Account-level separation provides a strong isolation boundary for security, billing, and access. Accounts should be organized into a hierarchy of organizational units (OUs) within AWS Organizations, with Service Control Policies (SCPs) applied at the OU level to enforce guardrails.

**Risks to flag:**

- Resources for unrelated workloads or different sensitivity levels placed in the same account without account-level separation. (Medium — SEC01-BP01)
- AWS Organizations OUs with no SCPs applied, meaning member accounts have no preventative guardrails. (Medium — SEC01-BP01)
- SCPs being removed or weakened on member accounts, which reduces the guardrail boundary. (High — SEC03-BP05)
- Member account root user access not restricted by SCPs (e.g., missing "Disallow Actions as a Root User" control). (Medium — SEC01-BP02)

## Root User Security

The root user has full administrative access and cannot be constrained by IAM policies. It should never be used for routine tasks. Root user access keys should not exist.

**Risks to flag:**

- Root user access keys being created or present. These should be deleted immediately. (High — SEC01-BP02)
- Root user being used for tasks other than the few that specifically require it. (High — SEC01-BP02)
- Missing MFA configuration on root user accounts. (High — SEC01-BP02)

## IAM Users vs. Federated Identities

IAM users with long-term credentials (passwords and access keys) should be avoided in favor of federated identities using IAM Identity Center (SSO) or direct SAML/OIDC federation. IAM roles with temporary credentials are the preferred access mechanism for both human and machine identities.

**Risks to flag:**

- New IAM users being created. Prefer federated access through IAM Identity Center or an external identity provider. (Medium — SEC02-BP02, SEC02-BP04)
- IAM access keys being created for IAM users. Prefer temporary credentials via IAM roles. (Medium — SEC02-BP02)
- Long-term credentials (access keys) that are not being rotated. Maximum rotation interval should be 90 days. (Medium — SEC02-BP05)
- IAM users without MFA enabled. MFA should be required for all human identities. (High — SEC02-BP01)

## Least Privilege Permissions

IAM policies should grant only the minimum permissions needed. Wildcard actions (`*`) and wildcard resources (`*`) should be avoided. Permission boundaries and SCPs should constrain the maximum set of grantable permissions.

**Risks to flag:**

- IAM policies with `Action: "*"` or `Resource: "*"` granting overly broad access. (High — SEC03-BP02)
- IAM policies granting full administrator access (`AdministratorAccess` or equivalent) to non-emergency roles. (High — SEC03-BP02)
- Missing permission boundaries on IAM roles that could be used to create other roles or policies (privilege escalation risk). (Medium — SEC03-BP05)
- Inline IAM policies on users instead of managed policies attached to groups or roles. Inline policies are harder to audit and manage. (Low — SEC02-BP06)

## Cross-Account and Public Access

Resources shared across accounts or made publicly accessible should be explicitly controlled and monitored. Resource-based policies (e.g., S3 bucket policies, SNS topic policies, SQS queue policies, KMS key policies) should not unintentionally grant public access.

**Risks to flag:**

- Resource policies with `Principal: "*"` without restrictive conditions, which grants public access. (High — SEC03-BP07)
- S3 bucket policies or ACLs allowing public read/write access. (High — SEC03-BP07)
- IAM role trust policies with overly broad principals or missing conditions (e.g., no `aws:SourceAccount` or `aws:SourceArn` condition). (Medium — SEC03-BP09)
- Cross-account role trust policies without an external ID condition when granting access to third parties. (Medium — SEC03-BP09)
- IAM role trust policies using the default trust policy without any conditions. (Medium — SEC03-BP09)

## Secrets Management

Application credentials, API keys, database passwords, and other secrets should be stored in AWS Secrets Manager or AWS Systems Manager Parameter Store with automatic rotation enabled. Secrets should never be hardcoded in source code, configuration files, or environment variables.

**Risks to flag:**

- Hardcoded secrets or credentials visible in Terraform configuration (e.g., plaintext passwords in resource definitions). (High — SEC02-BP03)
- Database credentials defined inline in Terraform rather than referencing Secrets Manager. (Medium — SEC02-BP03)
- Secrets Manager secrets without automatic rotation configured. (Low — SEC02-BP03)

## IaC and Automated Security Controls

Security controls should be defined as Infrastructure as Code, stored in version control, tested in CI/CD pipelines, and deployed automatically. Manual changes to security controls through the console should be avoided.

**What good looks like:**

- Security controls defined in Terraform/CloudFormation and deployed through pipelines
- Service Catalog used for approved templates
- AWS Config rules and Security Hub standards deployed for detective controls
- SCPs deployed via code for preventative guardrails

## AWS Documentation References

### Pillar Documentation

- [Security Pillar — AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)

### Source Questions

- [SEC 1 — How do you securely operate your workload?](https://docs.aws.amazon.com/wellarchitected/latest/framework/sec-01.html)
- [SEC 2 — How do you manage authentication for people and machines?](https://docs.aws.amazon.com/wellarchitected/latest/framework/sec-02.html)
- [SEC 3 — How do you manage permissions for people and machines?](https://docs.aws.amazon.com/wellarchitected/latest/framework/sec-03.html)
