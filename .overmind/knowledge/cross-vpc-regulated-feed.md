---
name: cross-vpc-regulated-feed
description: Why the internal-services security group's port 9090 ingress rule and its internal_cidr CIDR scoping (10.0.0.0/8 vs 10.0.0.0/16) exist, what depends on them across the fraud_detection_to_core VPC peering connection into the fraud-detection VPC (10.50.0.0/16), and the incident that led to the current scoping. Covers the regulated PCI transaction feed, the fraud-ingest NLB and txn-feed target group, the fraud-processor consumer, and Risk-team ownership/on-call routing.
---

# Cross-VPC Regulated Transaction Feed: Core VPC ↔ Fraud-Detection VPC

## Why this connection exists

The `fraud-processor` service in the fraud-detection VPC (`10.50.0.0/16`, owned by the Risk team) depends on access to `production-api-server` in the core VPC (`10.0.0.0/16`) across the `fraud_detection_to_core` peering connection. It reads a regulated transaction feed on port 9090 through the internal `fraud-ingest` NLB and `txn-feed` target group, which health-checks and pulls from the API server's private IP. This is not incidental connectivity — it's how transactions get scored for fraud risk within seconds of being processed, before settlement.

None of this is wired up as a Terraform reference. The `internal_cidr` variable on the `internal-services` security group is just a CIDR string; it has no `depends_on` or interpolated attribute pointing at the fraud-detection VPC, the peering connection, or the NLB. The only way to see this dependency is to trace the live peering connection and NLB target health — a Terraform plan for a change to `internal_cidr` will never mention any of this.

The `internal_cidr` value is deliberately scoped to `10.0.0.0/8` rather than the smaller `10.0.0.0/16` core-VPC-only range, specifically so it also covers the fraud-detection VPC's `10.50.0.0/16` range. This is the tightest rule that still lets `fraud-processor` reach the feed — it is not an oversight, and "matches the VPC CIDR exactly" is not actually the more secure state here, even though it looks that way in a diff.

## Compliance and data classification

Traffic on port 9090 across this peering connection is the live PCI-scoped transaction feed — the same data class as the primary payment path, just mirrored to the fraud-detection service for risk scoring. That is why the CIDR is scoped this tightly in the first place, rather than opened via a broader internal-mesh allow rule: it is the only private network path this regulated data is approved to travel over.

`production-api-server` also has a public endpoint (`aws_eip.api_server`, fronted by Route 53 on port 443) for customer traffic. If the private peering path is narrowed or removed, that public endpoint is the only remaining route by which the fraud-detection side could still reach the feed — which means regulated transaction data would have to cross the public internet to get there. That's not a graceful degradation; it's a PCI-DSS network-segmentation violation. Treat any change that narrows or removes the `10.50.0.0/16` range from `internal_cidr` as a compliance-relevant finding, not just a connectivity one, even when the change is framed as "security hardening."

VPC Flow Logs are enabled on the fraud-detection VPC specifically to maintain an audit trail for this regulated path — if you see flow log volume drop to zero for traffic between `10.0.0.0/16` and `10.50.0.0/16`, that's consistent with this exact failure mode, not just reduced traffic.

## Previous incident

In late 2025, a change to `internal-services` that was framed as routine hardening (narrowing an ingress rule that "looked" overly broad) replaced the `10.0.0.0/8` scoping with the core VPC's own `/16` range. The PR read as an unambiguous improvement — smaller CIDR, matches the VPC, no policy violations — and passed review in under an hour.

The fraud-detection side lost its feed silently. `fraud-processor` kept running against stale/cached data for several hours before anyone noticed, because nothing on the core platform team's side was affected — the API server kept serving customers normally, and the failure only showed up as unhealthy NLB targets inside the fraud-detection VPC, which the deploying team had no visibility into and no reason to check. By the time the Risk team traced it back to the security group change, several hours of transactions had been scored without fresh fraud signal. The fix was a one-line revert, but the detection gap was the real cost.

**Lesson:** any narrowing of `internal_cidr` on `internal-services` needs to be checked against the fraud-detection VPC's `10.50.0.0/16` range before merging, regardless of how safe the change looks in isolation — the security group's own owner has no visibility into who's on the consuming end of this connection, which is exactly how the previous incident went undetected for hours.

## Ownership

The fraud-detection VPC, `fraud-ingest` NLB, and `fraud-processor` consumer are owned by the Risk team (`risk-oncall@example.com`). Changes to `internal-services` that affect the `10.50.0.0/16` range should be reviewed by the Risk team before merging, not just the team that owns the core VPC — the person narrowing this security group has typically never heard of the fraud-detection VPC, which is exactly why this file exists.
