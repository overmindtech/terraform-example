---
name: aws-storage-data-management
description: AWS Well-Architected best practices for storage and data lifecycle management, including S3 lifecycle policies and storage classes, RDS and DynamoDB configuration, backup plans, snapshots, versioning, data transfer optimization, and VPC endpoints for storage access. Relevant when changes affect how data is stored, retained, backed up, or transferred.
---

# Storage and Data Management

The [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) is a collection of best practices published by AWS, organized into six pillars: Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, and Sustainability. When a Terraform change conflicts with a best practice described below, raise a risk. Each risk item includes a severity (High, Medium, or Low) and the originating best practice ID. Use the indicated severity and reference the best practice ID in the risk description.

This document draws from the Performance Efficiency Pillar (PERF3), Reliability Pillar (REL9), Sustainability Pillar (SUS4), and Cost Optimization Pillar (COST8).

## Storage Type Selection

The storage solution should match the data access patterns and performance requirements. Using one storage type for all workloads is an anti-pattern. Consider purpose-built data stores: relational databases (RDS/Aurora) for structured transactional data, DynamoDB for key-value access, S3 for object storage, ElastiCache for caching, and EFS/FSx for shared file systems.

**Risks to flag:**

- Using a single database type (e.g., RDS MySQL) for all workloads regardless of access patterns. Some workloads may be better served by DynamoDB, ElastiCache, or S3. (Low — PERF03-BP01)
- Using one EBS volume type (e.g., gp2) for all workloads without evaluating gp3, io2, or st1 based on IOPS and throughput needs. (Medium — PERF03-BP02)
- Using provisioned IOPS (io2) for workloads that don't need guaranteed IOPS performance. (Low — PERF03-BP02)
- Using gp2 instead of gp3 — gp3 offers 20% lower cost with the same baseline performance and allows independent IOPS and throughput configuration. (Low — PERF03-BP02)

## Backup and Recovery

All critical data should be backed up automatically on a defined schedule. Backups should be encrypted, stored in a separate security domain from production data, and tested periodically to verify integrity and recoverability within RTO/RPO targets.

**Risks to flag:**

- RDS instances or Aurora clusters without automated backups enabled (`backup_retention_period = 0`). (High — REL09-BP01)
- EBS volumes used for critical data without snapshot schedules configured via AWS Backup or Data Lifecycle Manager. (Medium — REL09-BP01)
- S3 buckets containing critical data without versioning enabled. Without versioning, accidental deletes or overwrites are permanent. (Medium — REL09-BP01)
- DynamoDB tables without point-in-time recovery (PITR) enabled. (Medium — REL09-BP01)
- Backups stored unencrypted. (Medium — REL09-BP02)
- Backups accessible with the same credentials as production data. Backup access should require separate, restricted permissions. (Medium — REL09-BP02)
- Manual backup processes instead of automated backup schedules. (Low — REL09-BP03)
- No periodic testing of backup restoration — assuming backups are valid without verification. (Medium — REL09-BP04)

## S3 Lifecycle and Storage Classes

S3 buckets should have lifecycle policies to transition objects to lower-cost storage classes (Intelligent-Tiering, Glacier, Deep Archive) as access frequency decreases, and to expire objects that are no longer needed. Versioning should be enabled for critical data but combined with lifecycle rules to expire old versions.

**Risks to flag:**

- S3 buckets with large amounts of data but no lifecycle policies configured. Data accumulates in S3 Standard indefinitely at higher cost. (Medium — SUS04-BP03)
- S3 versioning enabled without lifecycle rules to expire old versions. This leads to unbounded storage growth. (Medium — SUS04-BP05)
- Large datasets stored entirely in S3 Standard when most data is rarely accessed and could be in Infrequent Access or Glacier. (Low — SUS04-BP02)

## Data Transfer Optimization

Data transfer costs can be significant. Use VPC endpoints to access S3, DynamoDB, and other AWS services over private networks instead of the internet, avoiding NAT Gateway data processing charges and improving security. CloudFront can reduce data transfer costs for frequently accessed content.

**Risks to flag:**

- Accessing S3 or DynamoDB from within a VPC without VPC endpoints, routing traffic through NAT Gateway or the internet. VPC Gateway Endpoints for S3 and DynamoDB are free. (Medium — COST08-BP03)
- Large data transfers between regions without considering S3 Transfer Acceleration or CloudFront for optimization. (Low — COST08-BP02)
- Over-provisioned EBS volumes or file systems. Monitor utilization and right-size or use elastic file systems (EFS) that scale automatically. (Low — SUS04-BP04)

## Data Lifecycle

Data should have defined retention periods based on business, regulatory, and compliance requirements. Data that is no longer needed should be automatically deleted. Redundant copies of easily reproducible data should be eliminated.

**What good looks like:**

- S3 lifecycle policies transitioning data through storage classes and expiring old versions
- Automated backups via AWS Backup with defined retention and cross-region copy
- VPC Gateway Endpoints for S3 and DynamoDB in all VPCs
- EBS volumes using gp3 with appropriate IOPS/throughput configuration
- Periodic backup restoration testing
- DynamoDB PITR enabled for critical tables

## AWS Documentation References

### Pillar Documentation

- [Performance Efficiency Pillar — AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/performance-efficiency-pillar/welcome.html)
- [Reliability Pillar — AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/welcome.html)
- [Sustainability Pillar — AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/sustainability-pillar/sustainability-pillar.html)
- [Cost Optimization Pillar — AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/welcome.html)

### Source Questions

- [PERF 3 — How do you store, manage, and access data in your workload?](https://docs.aws.amazon.com/wellarchitected/latest/framework/perf-03.html)
- [REL 9 — How do you back up data?](https://docs.aws.amazon.com/wellarchitected/latest/framework/rel-09.html)
- [SUS 4 — How do you take advantage of data management policies and patterns to support your sustainability goals?](https://docs.aws.amazon.com/wellarchitected/latest/framework/sus-04.html)
- [COST 8 — How do you plan for data transfer charges?](https://docs.aws.amazon.com/wellarchitected/latest/framework/cost-08.html)
