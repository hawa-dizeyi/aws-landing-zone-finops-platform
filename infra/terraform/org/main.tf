resource "aws_organizations_organization" "this" {
  feature_set = "ALL"

  aws_service_access_principals = var.org_service_access_principals

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
  ]
}

resource "time_sleep" "after_org" {
  depends_on      = [aws_organizations_organization.this]
  create_duration = "20s"
}

# OUs
resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "shared" {
  name      = "SharedServices"
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "Sandbox"
  parent_id = aws_organizations_organization.this.roots[0].id
}

locals {
  ou_ids = {
    Security       = aws_organizations_organizational_unit.security.id
    SharedServices = aws_organizations_organizational_unit.shared.id
    Workloads      = aws_organizations_organizational_unit.workloads.id
    Sandbox        = aws_organizations_organizational_unit.sandbox.id
  }
}

# SCP: baseline guardrails (starter set - we’ll expand later)
resource "aws_organizations_policy" "scp_baseline" {
  depends_on  = [time_sleep.after_org]
  name        = "scp-baseline-guardrails"
  description = "Baseline guardrails to reduce foot-guns across accounts"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyLeavingOrganization"
        Effect = "Deny"
        Action = [
          "organizations:LeaveOrganization"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyDisablingCloudTrail"
        Effect = "Deny"
        Action = [
          "cloudtrail:StopLogging",
          "cloudtrail:DeleteTrail",
          "cloudtrail:UpdateTrail"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyS3PublicAccessBlockOff"
        Effect = "Deny"
        Action = [
          "s3:PutAccountPublicAccessBlock"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach SCP to all OUs
resource "aws_organizations_policy_attachment" "scp_security" {
  policy_id = aws_organizations_policy.scp_baseline.id
  target_id = aws_organizations_organizational_unit.security.id
}

resource "aws_organizations_policy_attachment" "scp_shared" {
  policy_id = aws_organizations_policy.scp_baseline.id
  target_id = aws_organizations_organizational_unit.shared.id
}

resource "aws_organizations_policy_attachment" "scp_workloads" {
  policy_id = aws_organizations_policy.scp_baseline.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_policy_attachment" "scp_sandbox" {
  policy_id = aws_organizations_policy.scp_baseline.id
  target_id = aws_organizations_organizational_unit.sandbox.id
}

# Account vending
resource "aws_organizations_account" "accounts" {
  for_each = var.enable_account_vending ? var.accounts : {}

  name      = each.value.name
  email     = each.value.email
  role_name = try(each.value.role_name, "OrganizationAccountAccessRole")
  parent_id = local.ou_ids[each.value.ou]

  lifecycle {
    prevent_destroy = true
  }
}
