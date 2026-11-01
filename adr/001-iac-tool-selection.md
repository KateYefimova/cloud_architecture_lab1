# 1. Choice of IaC Tool

## Status
Accepted

## Context
We need a declarative Infrastructure-as-Code tool to provision and manage AWS resources (VPC, subnets, gateways, IAM policies) ensuring full reproducibility and easy clean-up for Milestone 1.

## Decision
We choose **Terraform** (by HashiCorp) as our primary IaC tool.

## Alternatives Considered
- **AWS CloudFormation:** Native to AWS, but uses verbose YAML/JSON templates and lacks the modular flexibility and rich ecosystem of Terraform modules.
- **AWS CDK:** Allows writing infrastructure in programming languages (Python/TypeScript), which is powerful, but introduces an abstraction layer that obscures underlying CloudFormation mechanics, making it harder to debug raw sandbox errors.

## Consequences
- **Positive:** Declarative state management, excellent change preview (`terraform plan`), modularity, and drift detection capabilities.
- **Negative:** Requires managing a state file (though for a sandbox project, local state or a basic backend is sufficient).