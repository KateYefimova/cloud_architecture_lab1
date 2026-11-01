# 2. Stack Layout: Monolithic vs. Separated Network and Application

## Status
Accepted

## Context
As our key-value store evolves through the milestones (adding coordinators, shards, replication, and monitoring), our infrastructure will grow. We need to decide whether to keep all resources in a single IaC stack or separate foundational network infrastructure from application components.

## Decision
We choose a **modular, separated stack layout**: separating foundational networking (`vpc` module/stack) from future application components (compute, databases, or container clusters).

## Alternatives Considered
- **Single Monolithic Stack:** Putting VPC, IAM roles, and future compute resources into one giant state/stack.

## Consequences
- **Positive:** Network infrastructure changes rarely compared to application code. Separating them prevents accidental destruction of core networking elements during application updates and speeds up CI/CD pipeline runs for application code.
- **Negative:** Requires passing outputs (like VPC ID and subnet IDs) from the network stack to application layers via remote state or configuration variables.