# 3. CIDR Addressing Scheme

## Status
Accepted

## Context
We need to allocate a private IP address space for our VPC that avoids overlaps with common corporate or local networks and provides enough space for public subnets, private subnets, and future scaling (shards and replicas).

## Decision
We will allocate a `/16` VPC CIDR block (e.g., `10.100.0.0/16`) and divide it into subnet blocks across multiple Availability Zones:
- VPC CIDR: `10.100.0.0/16` (~65,536 IP addresses)
- Public Subnets (across 2 AZs): `10.100.1.0/24` and `10.100.2.0/24`
- Private Subnets (across 2 AZs): `10.100.10.0/24` and `10.100.20.0/24`

## Alternatives Considered
- Using the default VPC range (`172.31.0.0/16`), which is often cluttered and lacks structured segmentation.
- Using a smaller `/20` block, which limits future subnet expansion.

## Consequences
- **Positive:** Clean, predictable IP allocation that leaves ample room for expanding private subnets when adding multiple database shards and replicas in subsequent milestones.
- **Negative:** None for a sandbox environment.