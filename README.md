# Project 04 - AWS Multi-Account Landing Zone & FinOps Governance Platform

This repo is a practical landing zone build (AWS Organizations + guardrails) with a FinOps data plane:
Cost & Usage Reports → Glue/Athena → multi-account insights, plus SageMaker-based anomaly detection and automated alerts.

## What’s in here (high level)
- `infra/terraform/org` — org, OUs, SCPs, account vending
- `infra/terraform/security` — org-level security/logging (CloudTrail, GuardDuty, Security Hub)
- `infra/terraform/finops` — CUR, Glue catalog, Athena queries/views
- `ml/` — pipelines and code for cost anomaly detection
- `apps/dashboard` — optional thin UI (Vercel) for showcasing

## How I run it
1) Deploy org + accounts:
~~~
cd infra/terraform/org
terraform init
terraform apply
~~~
