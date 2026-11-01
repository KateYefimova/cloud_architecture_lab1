# Change Proposal: Milestone 1 — Infrastructure Setup

## Status
Proposed / In Progress

## Context
As part of the Cloud Architectures capstone project, we are building a "light" version of a serverless key-value store (similar to DynamoDB). Milestone 1 focuses on setting up the foundational cloud infrastructure inside the AWS Academy sandbox environment. 

Because the sandbox imposes strict permission boundaries, we need to document the environment limits, design a secure network topology, and define Infrastructure-as-Code configurations for reproducibility.

## Proposed Changes
1. **Network Infrastructure (VPC):**
   - Create a dedicated VPC with a custom CIDR block.
   - Implement both **public subnets** (with an Internet Gateway and route table for public access) and **private subnets** (for internal isolation) across multiple Availability Zones.
2. **IAM & Security Analysis:**
   - Document the permissions allowed and denied by the default `LabRole` in the sandbox, detailing the discovery methodology.
   - Design an IaC template for a strict **View-Only IAM Policy** (read-only access).
   - Design an IaC template for an **Assumable Role** using this policy, and document sandbox limitations regarding its attachment.
3. **Operational Readiness:**
   - Document service quotas critical for Milestone 2 (sharding).
   - Calculate an estimated monthly budget for a 2-shard architecture and compare it against the sandbox credit ceiling.
   - Verify full stack recreatability (tear down and re-deploy via IaC).

## Verification Plan
- Run IaC validation and linting checks.
- Deploy the network stack into the AWS Academy sandbox.
- Perform a full `destroy` and `apply` cycle to test stack recreatability, measuring deployment time and identifying potential race conditions or errors.