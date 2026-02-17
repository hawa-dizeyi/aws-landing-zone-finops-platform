# Project 04 — AWS Multi-Account Landing Zone & FinOps Governance Platform

This project implements a **production-style AWS multi-account landing zone** with built-in governance, centralized security baselines, and a FinOps-ready data plane.

The goal is not just account provisioning, but establishing a **repeatable organizational foundation** that supports centralized audit visibility, cost transparency, and future automation (including ML-driven anomaly detection).

The platform is built and managed using Terraform, follows AWS delegated administrator patterns, and reflects how a real enterprise environment would be structured.

---

## Project Scope & Intent

This project focuses on three core outcomes:

### 1) Multi-account governance
- Enforced organizational structure
- Guardrails via SCPs
- Controlled account placement and lifecycle management

### 2) Organization-wide security & logging
- Centralized, immutable audit logging
- Org-level threat detection and security posture visibility
- Delegated administrator model (security and logging accounts)

### 3) FinOps-ready data foundation
- Payer-level Cost & Usage Reports (CUR)
- Cross-account replication into the centralized logging account
- Athena-ready structure for cost analytics and automation

---

## Repository Structure (High Level)

- `infra/terraform/org`  
  AWS Organizations setup: OUs, SCP guardrails, and account vending logic.

- `infra/terraform/security`  
  Organization-wide security baseline: centralized logging, CloudTrail, GuardDuty, and Security Hub using delegated administrators.

- `infra/terraform/finops`  
  Cost & Usage Reports (CUR), replication, Glue database, Athena workgroup, and FinOps data scaffolding.

- `sql/athena/cur`  
  Athena SQL scaffolding for CUR tables and cost analytics views.

- `ml/`  
  Future SageMaker pipelines for cost anomaly detection.

- `apps/dashboard`  
  Optional lightweight frontend (Vercel) for visualizing cost and security insights.

---

# Phase 1 — Organization & Governance Baseline (Completed)

### What was implemented
- AWS Organization with ALL features enabled
- Organizational Units (Security, Logging, Workloads, Sandbox)
- Service Control Policies (SCPs) enforcing baseline guardrails
- Account vending logic with quota-aware safeguards
- Terraform-managed state for deterministic, repeatable builds

### Design notes
- Governance layers are fully code-driven.
- SCPs prevent high-risk actions (leaving org, disabling audit logs, weakening guardrails).
- Account creation is optional to respect AWS account quota constraints.

This phase establishes the **control plane** of the landing zone.

---

# Phase 2 — Organization Security & Centralized Logging (Completed)

### What was implemented
- **Central logging account**
  - Encrypted S3 bucket
  - Lifecycle policies
  - Customer-managed KMS key
  - Public access fully blocked
  - Ownership controls enforced

- **Organization CloudTrail**
  - Multi-region
  - Log file validation enabled
  - Writes centrally to logging account

- **GuardDuty**
  - Delegated administrator model
  - Auto-enable for all organization members

- **Security Hub**
  - Delegated administrator model
  - Organization auto-enable
  - AWS Foundational Security Best Practices
  - CIS AWS Foundations Benchmark (region-compatible)

### Verification approach
Validation is performed via:
- AWS CLI checks
- Terraform state inspection
- Cross-account log delivery confirmation
- Org-wide service auto-enrollment confirmation

This reflects how production security baselines are verified in practice.

---

# Phase 3 — FinOps Data Plane (Completed)

Phase 3 connects governance and security with financial visibility.

### What was implemented

- **Cost & Usage Report (CUR)** at payer level
  - Parquet format
  - DAILY granularity
  - Athena integration artifacts enabled

- **Dedicated CUR delivery bucket**
  - Versioning enabled
  - Public access blocked
  - Ownership controls enforced

- **Cross-account replication**
  - CUR objects replicated into central logging account under `cur/`
  - Replication role with least-privilege IAM policy
  - Destination encrypted using central logging KMS key
  - Modern replication schema (delete marker + KMS source selection criteria configured)

- **Athena & Glue foundations**
  - Glue database created
  - Dedicated Athena workgroup for FinOps queries
  - SQL scaffolding committed for analytics layer

### Why this structure

CUR lands in a dedicated bucket for clean billing isolation.

Replication ensures:
- Centralized retention model
- Single authoritative audit and cost storage location
- Clean separation of billing delivery vs. governance storage

This mirrors real enterprise FinOps patterns.

---

# How to Deploy

## Phase 1 — Organization
```
cd infra/terraform/org
terraform init
terraform apply
```

## Phase 2 — Security & Logging
```
cd infra/terraform/security
terraform init
terraform apply
```

## Phase 3 — FinOps
```
cd infra/terraform/finops
terraform init
terraform apply
```

> Note  
> Some resources (e.g., Security Hub) may require import if already enabled.  
> This is intentional and reflects real-world environments rather than greenfield assumptions.

---

# Next Steps (Phase 3.2+)

- Create Athena external table from CUR Parquet artifacts
- Build views for:
  - Multi-account cost rollups
  - Service-level spend
  - Regional spend
  - Daily deltas and cost spikes
- Introduce automated cost alerting
- Add SageMaker-based anomaly detection
- Optional dashboard for executive visibility

---

# Why This Project Exists

This repository demonstrates:

- Real-world AWS landing zone design
- Delegated admin patterns across Organizations
- Cross-account IAM and replication design
- Secure centralized logging architecture
- FinOps data engineering foundations
- Terraform usage beyond basic resource provisioning

It bridges infrastructure, security, and financial governance in a practical, deployable model.
