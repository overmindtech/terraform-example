---
name: aws-high-availability
description: AWS Well-Architected best practices for high availability, fault tolerance, and disaster recovery, including multi-AZ deployments, auto scaling, health checks, fault isolation, cross-region replication, and backup strategies. Relevant when changes affect redundancy, failover, or recovery capabilities.
---

# High Availability and Disaster Recovery

The [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) is a collection of best practices published by AWS, organized into six pillars: Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, and Sustainability. When a Terraform change conflicts with a best practice described below, raise a risk. Each risk item includes a severity (High, Medium, or Low) and the originating best practice ID. Use the indicated severity and reference the best practice ID in the risk description.

This document draws from the Reliability Pillar (REL5, REL7, REL10, REL11, REL13).

## Multi-AZ Deployments

Production workloads should be distributed across multiple Availability Zones. Deploying to a single AZ creates a single point of failure — an AZ outage would take down the entire workload. Resources should be pre-provisioned across AZs (static stability) rather than relying on the ability to launch new resources during a failure.

**Risks to flag:**

- Production workloads deployed in only a single Availability Zone. (High — REL10-BP01)
- RDS instances without Multi-AZ enabled in production. (High — REL10-BP01)
- Auto scaling groups configured with subnets in only one AZ. (High — REL10-BP01)
- ELB configured with targets in only one AZ. (Medium — REL10-BP01)
- Insufficient pre-provisioned capacity — relying on the ability to dynamically provision resources during a failure (control plane dependency). (Medium — REL11-BP05)

## Auto Scaling and Dynamic Capacity

Workloads should scale automatically to meet demand. Auto scaling groups should have properly configured health checks, scaling policies, and capacity settings. Resources should be managed as code and provisioned through automation, not manually.

**Risks to flag:**

- Auto scaling groups without health checks configured, or using only EC2 status checks instead of ELB health checks for web workloads. (Medium — REL07-BP01)
- No auto scaling at all for workloads with variable demand — capacity is manually managed. (Medium — REL07-BP03)
- Auto scaling groups with insufficient maximum capacity to handle demand spikes. (Medium — REL07-BP03)
- Scaling policies that add capacity too slowly (long cooldown periods) relative to the rate of demand change. (Low — REL07-BP03)
- Resources provisioned manually (click-ops) instead of through IaC and automation. (Medium — REL07-BP01)

## Fault Isolation

Workloads should be designed to limit the blast radius of failures. Cell-based or bulkhead architectures isolate failures to a subset of traffic. Components should be loosely coupled so that one component's failure doesn't cascade to others.

**Risks to flag:**

- Tightly coupled application components where one service's failure brings down all others. (Medium — REL05-BP01)
- No circuit breakers, timeouts, or retry logic configured in service-to-service communication. (Low — REL05-BP03, REL05-BP05)
- Message queues (SQS) without dead-letter queues (DLQs) configured. Failed messages will be retried indefinitely, potentially creating cascading load. (Medium — REL05-BP04)
- Applying code changes or deployments to all instances/cells simultaneously without gradual rollout. (Medium — REL10-BP03)

## Component Failure Recovery

Systems should automatically detect and recover from component failures. Health checks, auto-healing, and automated failover should be configured at every layer.

**Risks to flag:**

- No alarms or monitoring configured for the workload. Outages may occur without notification. (High — REL11-BP01)
- No established RTO (Recovery Time Objective) and RPO (Recovery Point Objective) for the workload. Without these, there's no basis for DR planning. (Medium — REL13-BP01)
- Auto scaling groups without automated replacement of unhealthy instances. (Medium — REL11-BP03)
- Database deployments without automated failover (e.g., single-AZ RDS without Multi-AZ). (High — REL11-BP03)
- No storage replication configured for stateful workloads. (Medium — REL11-BP03)

## Disaster Recovery

Workloads should have a defined DR strategy appropriate to their RTO and RPO requirements. DR strategies range from backup-and-restore (hours to recover) through pilot light and warm standby to active-active multi-region (minutes to recover). The DR site configuration should match the primary site to avoid drift.

**Risks to flag:**

- No DR strategy defined — recovery is ad-hoc during a disaster. (High — REL13-BP02)
- DR resources in a secondary region that have drifted from the primary region's configuration (different instance types, missing security groups, outdated AMIs). (Medium — REL13-BP04)
- Manual DR processes that depend on human intervention during a crisis. (Medium — REL13-BP05)
- Recovery processes that depend on AWS control plane operations (creating new resources, modifying DNS) during a regional outage — these may be impaired. (Medium — REL11-BP04)
- Cross-region replication not configured for critical data stores when the DR strategy requires it. (High — REL13-BP02)

**What good looks like:**

- Multi-AZ deployments for all production workloads
- Auto scaling groups with ELB health checks spanning multiple AZs
- Static stability — enough pre-provisioned capacity to survive an AZ loss
- Defined RTO/RPO driving the DR strategy
- Automated failover and recovery at every layer
- Regular DR testing through game days or chaos engineering

## AWS Documentation References

### Pillar Documentation

- [Reliability Pillar — AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/welcome.html)

### Source Questions

- [REL 5 — How do you design interactions in a distributed system to mitigate or withstand failures?](https://docs.aws.amazon.com/wellarchitected/latest/framework/rel-05.html)
- [REL 7 — How do you design your workload to adapt to changes in demand?](https://docs.aws.amazon.com/wellarchitected/latest/framework/rel-07.html)
- [REL 10 — How do you use fault isolation to protect your workload?](https://docs.aws.amazon.com/wellarchitected/latest/framework/rel-10.html)
- [REL 11 — How do you design your workload to withstand component failures?](https://docs.aws.amazon.com/wellarchitected/latest/framework/rel-11.html)
- [REL 13 — How do you plan for disaster recovery (DR)?](https://docs.aws.amazon.com/wellarchitected/latest/framework/rel-13.html)
