---
name: multi-region-architecture
description: How our multi-region infrastructure is designed, including the VPC peering mesh, service discovery, cross-region dependencies, and design decisions. Written for engineers who need context on why things are set up this way.
---

# Multi-Region Architecture

## Regions

We operate in 4 AWS regions: us-east-1 (primary), us-west-2, eu-west-1, ap-southeast-1. us-east-1 hosts central resources (central SNS topic, central S3 bucket, central KMS key). The other regions are peers.

## VPC Peering Mesh

All 4 regions are connected via a full mesh of VPC peering connections (6 total). DNS resolution is enabled on all peering connections and this is intentional - it's required for cross-region service discovery. Services in one region need to resolve private DNS names of services in other regions.

If someone is enabling DNS resolution on a peering connection, that's moving towards the correct state, not introducing risk. Having DNS resolution DISABLED is actually the problem since it means service discovery is broken for that region pair. All VPCs are in the same account so cross-VPC DNS resolution doesn't create a trust boundary issue.

The peering mesh means a change to any VPC or its routing can have far-reaching effects. A route table modification in us-east-1 could affect traffic flowing through peering connections to eu-west-1.

## S3 Access Pattern

We don't use NAT gateways (cost optimization). Instead, Lambda functions and services in private subnets access S3 through VPC Gateway Endpoints. Each region has an S3 endpoint attached to its private route table.

This creates a non-obvious dependency chain: services → private route table → VPC endpoint → S3. Changes to VPC routing or peering that add/modify routes could interfere with the endpoint's prefix list routes and break S3 access. The VPC endpoint doesn't show many Terraform edges but it's on the critical path for all S3 operations from private subnets.

## Central Resources in us-east-1

Three central resources live in us-east-1 and are referenced by resources in all regions:

1. **Central SNS topic** - all SQS queues subscribe, all Lambda functions publish
2. **Central S3 bucket** - referenced by Lambda function environment variables (CENTRAL_BUCKET)
3. **Central KMS key** - multi-region key used for encryption of the KMS-encrypted S3 bucket and EBS volume

Changes to any central resource potentially affect all 4 regions. The central SNS topic has the widest blast radius because it has both subscriber edges (SQS subscriptions in Terraform) and publisher edges (Lambda env vars, not visible as Terraform dependencies).

## Configuration Distribution

Runtime configuration is distributed via SSM Parameter Store. Parameters under `/ovm-scale/` in each region contain JSON with references to that region's SNS topic ARNs, SQS queue URLs, and VPC IDs. Services read these at startup and cache them.

The implication is that if a referenced resource is replaced (destroyed and recreated, which changes its ARN), the SSM parameters become stale. The parameters themselves won't show up in the Terraform plan diff but they'll contain invalid ARNs. This is especially sneaky because the failure only shows up at runtime when a service tries to use the stale reference.

SecureString parameters under the same path are encrypted with KMS, so KMS key access changes can cascade to parameter decryption failures.
