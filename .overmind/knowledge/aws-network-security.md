---
name: aws-network-security
description: AWS Well-Architected best practices for network architecture and network security, including VPCs, subnets, security groups, NACLs, route tables, gateways, VPC peering, Transit Gateway, load balancers, CloudFront, and network segmentation. Relevant when changes affect network topology, traffic flow, or network-level access controls.
---

# Network Architecture and Security

The [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) is a collection of best practices published by AWS, organized into six pillars: Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, and Sustainability. When a Terraform change conflicts with a best practice described below, raise a risk. Each risk item includes a severity (High, Medium, or Low) and the originating best practice ID. Use the indicated severity and reference the best practice ID in the risk description.

This document draws from the Security Pillar (SEC5), Reliability Pillar (REL2), and Performance Efficiency Pillar (PERF4).

## Network Segmentation and Layers

Workload components should be segmented into network layers based on their function, data sensitivity, and access requirements. Public-facing endpoints (load balancers, API gateways, CloudFront) should be in public subnets, while application logic and databases should be in private subnets. Different sensitivity levels may warrant separate subnets, VPCs, or even separate accounts.

**Risks to flag:**

- All resources placed in a single VPC or a single subnet with no network layering. Components with different functions and sensitivity levels should be segmented. (Medium — SEC05-BP01)
- Databases or backend services deployed in public subnets. Data-tier resources should always be in private subnets. (High — SEC05-BP01)
- EC2 instances, ECS tasks, or Lambda functions in public subnets when they don't need direct internet access. Prefer private subnets with NAT gateways or VPC endpoints. (Medium — SEC05-BP01)

## Security Groups and Traffic Control

Security groups should follow the principle of least privilege for network access. Both inbound and outbound rules should be explicitly defined. Traffic should be controlled at every layer boundary, not just at the perimeter.

**Risks to flag:**

- Security groups with ingress rules allowing `0.0.0.0/0` (all traffic) on sensitive ports like SSH (22), RDP (3389), or database ports (3306, 5432, 1433, 27017). (High — SEC05-BP02)
- Security groups with egress rules allowing all traffic to all destinations when the workload only needs specific outbound access. (Low — SEC05-BP02)
- Security groups with broad port ranges (e.g., 0-65535) instead of specific ports needed by the application. (Medium — SEC05-BP02)
- Removing or weakening existing security group rules that restrict access. (Medium — SEC05-BP02)
- Relying solely on perimeter security (NACLs at subnet boundary) without security groups on individual resources. (Medium — SEC05-BP02)

## VPC and Subnet Design

VPC CIDR blocks should be sized to accommodate current needs and future growth. Subnets should span multiple Availability Zones. IP address ranges should not overlap with other connected networks (on-premises, peered VPCs, other cloud providers).

**Risks to flag:**

- VPC CIDR blocks that are very small (e.g., /28) for production workloads, leaving no room for growth. Cannot be changed after creation. (Medium — REL02-BP03)
- Subnets only in a single Availability Zone, creating a single point of failure. (High — REL02-BP03)
- VPC CIDR ranges that overlap with other VPCs or on-premises networks that need connectivity. This prevents peering and Transit Gateway attachments. (High — REL02-BP05)
- Excessively large CIDR blocks (e.g., /16 for small workloads) that waste address space and may conflict with future peering needs. (Low — REL02-BP05)

## Network Topology and Connectivity

For connecting multiple VPCs, prefer hub-and-spoke topology using AWS Transit Gateway over complex VPC peering meshes. For hybrid connectivity, use redundant connections (multiple Direct Connect or VPN tunnels) across different Availability Zones.

**Risks to flag:**

- Complex many-to-many VPC peering relationships instead of using Transit Gateway as a central hub. (Medium — REL02-BP04)
- Providing routes between networks that should not communicate with one another. (Medium — REL02-BP04)
- A single VPN tunnel or Direct Connect connection as the only hybrid connectivity path — this is a single point of failure. (High — REL02-BP02)
- Multiple VPN tunnels that terminate in the same Availability Zone. (Medium — REL02-BP02)

## Public Endpoints and Edge Networking

Public-facing workloads should use managed, highly available services for their public endpoints: Route 53 for DNS, CloudFront for content delivery, ELB for load balancing, and API Gateway for APIs. Exposing individual EC2 instance public IPs directly is an anti-pattern.

**Risks to flag:**

- EC2 instances with public IP addresses serving as direct endpoints instead of being behind a load balancer or CloudFront. (Medium — REL02-BP01)
- Using IP addresses instead of domain names to locate services. (Low — REL02-BP01)
- Public-facing web applications without AWS WAF or Shield protection against DDoS and application-layer attacks. (Medium — REL02-BP01, SEC05-BP03)
- Internet-facing load balancers without CloudFront in front for global distribution and caching, when serving a geographically distributed user base. (Low — PERF04-BP02)

## Inspection and Firewall Protection

Traffic inspection should go beyond simple port/protocol rules. Use AWS WAF for HTTP-based traffic, AWS Network Firewall or third-party IPS for deep packet inspection, and Route 53 Resolver DNS Firewall for DNS-level filtering.

**What good looks like:**

- AWS WAF with managed rule groups attached to CloudFront, ALB, or API Gateway
- Network Firewall or Gateway Load Balancer with IPS for centralized inspection
- VPC Flow Logs enabled for network monitoring and troubleshooting
- DNS Firewall rules for controlling outbound DNS resolution
- Network protections defined as IaC and deployed through CI/CD pipelines

## AWS Documentation References

### Pillar Documentation

- [Security Pillar — AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
- [Reliability Pillar — AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/welcome.html)
- [Performance Efficiency Pillar — AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/performance-efficiency-pillar/welcome.html)

### Source Questions

- [SEC 5 — How do you protect your network resources?](https://docs.aws.amazon.com/wellarchitected/latest/framework/sec-05.html)
- [REL 2 — How do you plan your network topology?](https://docs.aws.amazon.com/wellarchitected/latest/framework/rel-02.html)
- [PERF 4 — How do you select and configure networking resources in your workload?](https://docs.aws.amazon.com/wellarchitected/latest/framework/perf-04.html)
