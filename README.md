# Project 04 — AWS Multi-Account Landing Zone & FinOps Governance Platform

This repository implements a production-style **AWS multi-account landing zone** with governance guardrails, centralized security baselines, and a FinOps-ready data foundation.

The goal is not just account provisioning, but building a repeatable organization setup that supports **audit visibility, cost transparency, and automation** (including ML-driven anomaly detection later on).

Everything is managed with Terraform and follows AWS delegated administrator patterns to reflect how multi-account environments are commonly operated in practice.

---

## Project Scope & Intent

This project focuses on three outcomes:

### 1) Multi-account governance
- Enforced organization structure and OU layout
- Guardrails through SCPs
- Controlled account placement and lifecycle management

### 2) Organization-wide security & logging
- Centralized audit logging with retention controls
- Org-wide threat detection and posture visibility
- Delegated administrator model (security + logging accounts)

### 3) FinOps-ready data foundation
- Payer-level Cost & Usage Reports (CUR)
- Cross-account replication into the centralized logging account
- Athena + Glue for cost analytics and automation

---

## Repository Structure (High Level)

- `infra/terraform/org`  
  AWS Organizations setup (OUs, SCP guardrails, account vending).

- `infra/terraform/security`  
  Security baseline (central logging, org CloudTrail, GuardDuty, Security Hub) using delegated administrators.

- `infra/terraform/finops`  
  CUR delivery, replication, Glue database, Athena workgroup, and FinOps data plane wiring.

- `sql/athena/cur`  
  Athena SQL scaffolding for analytics views (cost rollups, deltas, top movers).

- `ml/`  
  Future SageMaker pipelines for anomaly detection.

- `apps/dashboard`  
  Optional lightweight frontend (Vercel) for visualizing cost and security insights.

---

# Phase 1 — Organization & Governance Baseline (Completed)

### What was implemented
- AWS Organization with ALL features enabled
- Organizational Units: Security, Logging, Workloads, Sandbox
- Baseline SCP guardrails
- Account vending logic (quota-aware)
- Terraform-managed state for deterministic builds

### Design notes
- Governance is fully code-driven.
- SCPs prevent high-risk actions (leaving the org, weakening audit controls, disabling logging).
- Account creation is optional to respect AWS account quota constraints.

This phase establishes the **control plane**.

---

# Phase 2 — Organization Security & Centralized Logging (Completed)

### What was implemented
- **Central logging account**
  - Encrypted S3 bucket (KMS)
  - Lifecycle policies and retention controls
  - Public access blocked
  - Ownership controls enforced

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
  - CIS AWS Foundations Benchmark (region-compatible)

### Verification approach
Validation is performed via:
- AWS CLI checks
- Terraform state inspection
- Cross-account log delivery confirmation
- Org-wide service enrollment confirmation

This mirrors how security baselines are typically validated in production environments.

---

# Phase 3 — FinOps Data Plane (Completed)

Phase 3 connects governance and security with financial visibility.

### What was implemented
- **Cost & Usage Report (CUR)** at payer level
  - Parquet format
  - DAILY granularity
  - Athena artifacts enabled

- **Dedicated CUR delivery bucket**
  - Versioning enabled
  - Public access blocked
  - Ownership controls enforced
  - SSE-KMS enforced to support replication filtering

- **Cross-account replication**
  - CUR objects replicated into the central logging bucket under `cur/`
  - Replication role with least-privilege IAM policy
  - Destination encrypted using the central logging KMS key

- **Athena & Glue foundations**
  - Glue database created (`cur_db`)
  - Dedicated Athena workgroup (`finops`)
  - Query results stored centrally under `athena-results/`

### Why this structure
CUR lands in a dedicated delivery bucket for billing isolation.

Replication provides:
- Central retention and access model
- One authoritative audit + cost storage location
- Clean separation between billing delivery and governance storage

---

# Phase 3.2 — Analytics Layer (Athena + Glue) (Completed)

Phase 3.2 turns raw CUR data into a queryable analytics layer.

### What was implemented
- Glue Catalog database: `cur_db`
- CUR table cataloged as: `cur_org_cur`
- Athena workgroup isolation: `finops`
- Partition discovery and repairs for Parquet layout (`MSCK REPAIR TABLE`)
- Baseline query patterns for:
  - Daily spend (account/service/region)
  - Day-over-day deltas and top movers
  - Month-to-date rollups

### Evidence (Phase 3.2)
- Athena database + table:  
  `docs/screenshots/phase-3-2/01-athena-curdb-table.png`
- Athena query returning rows:  
  `docs/screenshots/phase-3-2/02-athena-query-rows.png`
- Partition repair execution:  
  `docs/screenshots/phase-3-2/03-athena-msck-repair.png`
- Glue database + table:  
  `docs/screenshots/phase-3-2/04-glue-curdb-table.png`
- Replicated Parquet objects in central bucket:  
  `docs/screenshots/phase-3-2/05-s3-central-logs-cur-parquet.png`
- Terraform apply output (FinOps):  
  `docs/screenshots/phase-3-2/06-terraform-apply-finops.png`

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

### Phase 3.2 — Analytics initialization (Athena)
After CUR data lands and the Glue table exists:
```
MSCK REPAIR TABLE cur_db.cur_org_cur;
```
> Note  
> Some resources (e.g., Security Hub) may require import if already enabled.  
> This is intentional and reflects real-world environments rather than greenfield assumptions.

---

# Next Steps

- Phase 4: Event-driven automation (CUR delivery → Athena refresh → alerting)
- Cost spike detection logic + notifications (Slack/email)
- Phase 5: SageMaker-based anomaly scoring over daily features

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
