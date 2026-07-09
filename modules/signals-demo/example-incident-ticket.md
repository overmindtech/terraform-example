# Example incident ticket (for testing the Overmind assistant)

This is a sample support ticket written the way the **Risk team** (owners of the
fraud-detection VPC, `fraud-ingest` NLB, and `fraud-processor`) would actually
write it after the `internal_cidr` narrowing breaks their feed. It intentionally
contains **no mention of security groups, CIDRs, or the platform team's change** —
the Risk team has no visibility into the core VPC or the PR that caused this, and
wouldn't know to look there. That's the point: this is what the assistant would
have to work with in the real world, paste this into the Overmind assistant and
see whether it can trace it back to the actual change.

---

**Ticket:** RISK-2287
**Priority:** P1 — High
**Reporter:** risk-oncall@example.com
**Team / Component:** Risk Engineering / fraud-detection-platform / txn-feed
**Environment:** production

## Summary

Since approximately 14:40 UTC today, `fraud-processor` has stopped receiving new
records from the transaction feed it consumes from the core platform's API
service over our VPC peering connection. The `fraud-ingest` NLB's `txn-feed`
target group is reporting 0 healthy targets. We have not deployed or changed
anything in the fraud-detection VPC in the last 5 days.

## Timeline

- **14:40 UTC** — PagerDuty alert: `txn-feed target group: UnHealthyHostCount > 0` (all targets)
- **14:42 UTC** — On-call acknowledged. Confirmed `fraud-processor` instance is up, no application errors, no recent deploys.
- **14:45 UTC** — Confirmed the VPC peering connection to the core VPC still shows `active` in the AWS console. Route tables on our side unchanged.
- **14:50 UTC** — Ran a manual connectivity test from inside the fraud-detection VPC to the registered target IP on port 9090:
  ```
  $ nc -vz -w 5 10.0.1.42 9090
  nc: connect to 10.0.1.42 port 9090 (tcp) timed out: Operation now in progress
  ```
- **15:05 UTC** — Checked our own security groups and NACLs (`fraud-processor` SG, subnet NACLs) — no changes in the last 30 days, egress on 9090 is open on our end.
- **15:12 UTC** — Pulled target health detail via the AWS CLI:
  ```
  $ aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:...:targetgroup/txn-feed/...
  {
    "TargetHealthDescriptions": [{
      "Target": { "Id": "10.0.1.42", "Port": 9090 },
      "TargetHealth": {
        "State": "unhealthy",
        "Reason": "Target.Timeout",
        "Description": "Request timed out"
      }
    }]
  }
  ```
- **15:20 UTC** — Escalated to Risk Engineering on-call lead. Opening this ticket.

## Symptoms observed

- `fraud-ingest` NLB / `txn-feed` target group: all targets unhealthy, reason `Target.Timeout`
- `fraud-processor` application logs show repeated `ETIMEDOUT` errors polling the feed endpoint, first occurrence ~14:38 UTC
- No corresponding errors or alerts on any service we own outside of this feed
- We have no visibility into the core platform team's AWS account/VPC, so we can't tell if anything changed on their end

## What we've ruled out

- **Not a `fraud-processor` app issue** — instance healthy, no recent deploys, logs otherwise clean
- **Not the peering connection itself** — shows `active`, route tables on our side unchanged
- **Not a change on our side** — no Terraform applies or manual console changes on record for our VPC in the affected window
- **Not DNS** — NLB DNS resolves fine, target group has registered targets, they just fail health checks

## Business impact

- Live transactions are currently being scored using stale fraud signal only. We've paused auto-approval on high-value transactions and moved to manual review as a precaution — this is already causing a review backlog.
- This looks similar to the **PSR-2025-114** incident from December, where this same feed went down for several hours before anyone traced it back to a change on the platform side. If this is the same failure mode, we need to identify the change quickly — last time the detection gap was the expensive part, not the fix.
- This feed carries PCI-scoped transaction data. Any extended outage needs to be logged for audit purposes regardless of root cause.

## Ask

We don't have visibility into whatever produces this feed on the core platform
side. Given the timing, can someone check whether anything changed there in the
last few hours — networking, security groups, routing, peering config, anything?
Everything in our own environment is unchanged and healthy, so at this point we
can't debug further without knowing what changed upstream.
