data "aws_caller_identity" "mgmt" {}

data "aws_organizations_organization" "org" {}

############################################
# Central logging bucket + KMS (Logging Acct)
############################################

resource "aws_kms_key" "log_bucket" {
  provider                = aws.logging
  description             = "KMS key for central log bucket (CloudTrail / security logs)"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Full control for logging account root
      {
        Sid       = "AllowLoggingAccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.logging_account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },

      # Allow CloudTrail service to use the key when writing to S3
      {
        Sid       = "AllowCloudTrailEncrypt"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Encrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.mgmt.account_id
          }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "log_bucket" {
  provider      = aws.logging
  name          = "alias/central-log-bucket"
  target_key_id = aws_kms_key.log_bucket.key_id
}

resource "aws_s3_bucket" "central_logs" {
  provider = aws.logging
  bucket   = var.central_log_bucket_name
}

resource "aws_s3_bucket_public_access_block" "central_logs" {
  provider = aws.logging
  bucket   = aws_s3_bucket.central_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "central_logs" {
  provider = aws.logging
  bucket   = aws_s3_bucket.central_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "central_logs" {
  provider = aws.logging
  bucket   = aws_s3_bucket.central_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.log_bucket.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "central_logs" {
  provider = aws.logging
  bucket   = aws_s3_bucket.central_logs.id

  rule {
    id     = "log-retention"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    expiration {
      days = 365
    }
  }
}

# Bucket policy: allow CloudTrail to write mgmt + org logs
resource "aws_s3_bucket_policy" "central_logs" {
  provider = aws.logging
  bucket   = aws_s3_bucket.central_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.central_logs.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.mgmt.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.mgmt.account_id}:trail/${var.cloudtrail_trail_name}"
          }
        }
      },
      {
        Sid       = "AWSCloudTrailWriteMgmt"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.central_logs.arn}/AWSLogs/${data.aws_caller_identity.mgmt.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "aws:SourceAccount" = data.aws_caller_identity.mgmt.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.mgmt.account_id}:trail/${var.cloudtrail_trail_name}"
          }
        }
      },
      {
        Sid       = "AWSCloudTrailWriteOrg"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.central_logs.arn}/AWSLogs/${data.aws_organizations_organization.org.id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "aws:SourceAccount" = data.aws_caller_identity.mgmt.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.mgmt.account_id}:trail/${var.cloudtrail_trail_name}"
          }
        }
      }
    ]
  })
}

############################################
# Org CloudTrail (Management Acct)
############################################

resource "aws_cloudtrail" "org_trail" {
  name                          = var.cloudtrail_trail_name
  s3_bucket_name                = aws_s3_bucket.central_logs.bucket
  is_organization_trail         = true
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true

  depends_on = [
    aws_s3_bucket_policy.central_logs
  ]
}

############################################
# GuardDuty org delegated admin (Security Acct)
############################################

# Set delegated admin from management account
resource "aws_guardduty_organization_admin_account" "admin" {
  admin_account_id = var.security_account_id
}

resource "time_sleep" "after_guardduty_admin" {
  depends_on      = [aws_guardduty_organization_admin_account.admin]
  create_duration = "30s"
}

# Create detector in security account (delegated admin)
resource "aws_guardduty_detector" "security" {
  provider   = aws.security
  enable     = true
  depends_on = [time_sleep.after_guardduty_admin]
}

# Org auto-enable in security account
resource "aws_guardduty_organization_configuration" "org" {
  provider    = aws.security
  detector_id = aws_guardduty_detector.security.id

  auto_enable_organization_members = "ALL"

  depends_on = [
    aws_guardduty_detector.security
  ]
}

############################################
# Security Hub org delegated admin (Security Acct)
############################################

resource "aws_securityhub_organization_admin_account" "admin" {
  admin_account_id = var.security_account_id
}

# NOTE:
# If Security Hub is already enabled in the security account, import it:
# terraform import -provider=aws.security aws_securityhub_account.security <SECURITY_ACCOUNT_ID>
resource "aws_securityhub_account" "security" {
  provider = aws.security
  enable_default_standards = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_securityhub_organization_configuration" "org" {
  provider    = aws.security
  auto_enable = true

  depends_on = [aws_securityhub_account.security]
}

# Standards
resource "aws_securityhub_standards_subscription" "aws_foundational" {
  provider      = aws.security
  count         = var.enable_securityhub_standards ? 1 : 0
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/aws-foundational-security-best-practices/v/1.0.0"

  depends_on = [aws_securityhub_account.security]
}

resource "aws_securityhub_standards_subscription" "cis" {
  provider = aws.security
  count    = var.enable_securityhub_standards ? 1 : 0

  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/cis-aws-foundations-benchmark/v/1.4.0"

  depends_on = [aws_securityhub_account.security]
}
