# Project 04 — AWS Multi-Account Landing Zone & FinOps Governance Platform

This project implements a **production-style AWS multi-account landing zone** with built-in **governance, security baselines, and FinOps foundations**.

The goal is not just account provisioning, but establishing a **repeatable organizational baseline** that supports centralized security visibility, cost transparency, and future automation (including ML-driven cost anomaly detection).

The platform is built and managed using **Terraform**, follows AWS **delegated administrator patterns**, and is structured the way a real enterprise environment would be.

---

## Project Scope & Intent

This project focuses on three core outcomes:

1. **Multi-account governance**
   - Enforced organizational structure
   - Guardrails via SCPs
   - Controlled account placement and lifecycle

2. **Organization-wide security & logging**
   - Centralized, immutable audit logs
   - Org-level threat detection and security posture visibility
   - Delegated admin model (security and logging accounts)

3. **FinOps-ready data foundation**
   - Designed to ingest and analyze multi-account cost data
   - Prepared for analytics, automation, and ML-based anomaly detection

---

## Repository Structure (High Level)

- `infra/terraform/org`  
  AWS Organizations setup: OUs, SCP guardrails, and account vending logic.

- `infra/terraform/security`  
  Organization-wide security baseline: centralized logging, CloudTrail, GuardDuty, and Security Hub using delegated administrators.

- `infra/terraform/finops`  
  Cost & Usage Reports (CUR), Glue catalog, Athena queries, and multi-account cost views.

- `ml/`  
  SageMaker pipelines and supporting code for cost anomaly detection and analysis.

- `apps/dashboard`  
  Optional lightweight frontend (Vercel) for visualizing insights and showcasing outcomes.

---

## Phase 1 — Organization & Governance Baseline (Completed)

### What was implemented
- AWS Organization with **ALL features enabled**
- Organizational Units (Security, Logging, Workloads, Sandbox)
- Service Control Policies (SCPs) enforcing baseline guardrails
- Account vending logic with quota-aware safeguards
- Terraform-managed state for deterministic, repeatable builds

### Design notes
- Governance layers are intentionally **code-driven**, not UI-driven.
- SCPs focus on preventing irreversible or high-risk actions (leaving org, disabling audit logs, public access controls).
- Account creation is optional and controlled to accommodate AWS account quota limits.

This phase establishes the **control plane** of the landing zone.

---

## Phase 2 — Organization Security & Centralized Logging (Completed)

### What was implemented
- **Central logging account**
  - Encrypted S3 bucket with lifecycle policies
  - Customer-managed KMS key
  - Public access fully blocked

- **Organization CloudTrail**
  - Multi-region
  - Log file validation enabled
  - Writes centrally to the logging account

- **GuardDuty**
  - Delegated administrator model
  - Auto-enable for all organization members

- **Security Hub**
  - Delegated administrator model
  - Organization auto-enable
  - AWS Foundational Security Best Practices
  - CIS AWS Foundations Benchmark (region-compatible version)

### Verification approach
Rather than screenshots, validation is done through:
- AWS CLI checks
- Terraform state inspection
- Cross-account log delivery confirmation
- Successful org-level auto-enrollment of security services

This reflects how security baselines are typically verified in real environments.

---

## How to Deploy (So Far)

### Phase 1 — Organization
~~~
cd infra/terraform/org
terraform init
terraform apply
~~~

### Phase 2 — Security & Logging
~~~
cd infra/terraform/security
terraform init
terraform apply
~~~

> **Note**
> Some resources (for example, Security Hub) may require importing if they were already enabled before Terraform management.  
> This is handled intentionally to reflect real-world environments rather than greenfield assumptions.

---

## What’s Next — Phase 3 (In Progress)

The next phase builds the **FinOps data plane**, turning raw billing data into actionable insight:

- Cost & Usage Reports (CUR) at the payer level
- Glue catalog and schema management
- Athena views for:
  - Multi-account cost rollups
  - Service-level and regional spend
  - Daily deltas and trend analysis
- Foundations for:
  - Automated cost alerts
  - ML-based anomaly detection (SageMaker)

This phase connects governance and security controls with **financial visibility and optimization**.

---

## Why This Project Exists

This repository is designed to demonstrate:

- How real AWS landing zones are built and evolved over time
- Comfort with AWS Organizations, delegated administrator patterns, and cross-account access
- Practical Terraform usage beyond simple resource creation
- A clear bridge between infrastructure, security, and FinOps
