data "aws_caller_identity" "current" {}

############################################
# KMS for CUR delivery bucket (Payer/Mgmt)
############################################

resource "aws_kms_key" "cur_delivery" {
  description             = "KMS key for CUR delivery bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowPayerAccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowBillingReportsUseKey"
        Effect    = "Allow"
        Principal = { Service = "billingreports.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "cur_delivery" {
  name          = "alias/cur-delivery"
  target_key_id = aws_kms_key.cur_delivery.key_id
}

############################################
# CUR Delivery Bucket (Management/Payer Account)
############################################

resource "aws_s3_bucket" "cur_delivery" {
  bucket = var.cur_delivery_bucket_name
}

resource "aws_s3_bucket_ownership_controls" "cur_delivery" {
  bucket = aws_s3_bucket.cur_delivery.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "cur_delivery" {
  bucket = aws_s3_bucket.cur_delivery.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "cur_delivery" {
  bucket = aws_s3_bucket.cur_delivery.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cur_delivery" {
  bucket = aws_s3_bucket.cur_delivery.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.cur_delivery.arn
    }
  }
}

resource "aws_s3_bucket_policy" "cur_delivery" {
  bucket = aws_s3_bucket.cur_delivery.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "billingreports.amazonaws.com" }
        Action    = ["s3:GetBucketAcl", "s3:GetBucketPolicy"]
        Resource  = aws_s3_bucket.cur_delivery.arn
        Condition = {
          StringEquals = {
            "aws:SourceArn"     = "arn:aws:cur:us-east-1:${data.aws_caller_identity.current.account_id}:definition/*"
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid       = "AllowCURPutObject"
        Effect    = "Allow"
        Principal = { Service = "billingreports.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cur_delivery.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceArn"                   = "arn:aws:cur:us-east-1:${data.aws_caller_identity.current.account_id}:definition/*"
            "aws:SourceAccount"               = data.aws_caller_identity.current.account_id
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_ownership_controls.cur_delivery]
}

############################################
# CUR Definition (use us-east-1 endpoint)
############################################

resource "aws_cur_report_definition" "cur" {
  provider = aws.cur

  report_name                = var.cur_report_name
  time_unit                  = "DAILY"
  format                     = "Parquet"
  compression                = "Parquet"
  additional_schema_elements = ["RESOURCES"]
  refresh_closed_reports     = true
  report_versioning          = "OVERWRITE_REPORT"

  s3_bucket = aws_s3_bucket.cur_delivery.bucket
  s3_prefix = var.cur_s3_prefix
  s3_region = var.aws_region

  additional_artifacts = ["ATHENA"]

  depends_on = [aws_s3_bucket_policy.cur_delivery]
}

############################################
# Glue + Athena (foundation)
############################################

resource "aws_glue_catalog_database" "cur" {
  name = var.glue_database_name
}

resource "aws_athena_workgroup" "finops" {
  name = var.athena_workgroup_name

  configuration {
    enforce_workgroup_configuration = true

    result_configuration {
      output_location = "s3://${var.central_log_bucket_name}/${var.athena_results_prefix}/"
    }
  }
}

############################################
# Glue Crawler (CUR table)
############################################

data "aws_iam_policy_document" "glue_crawler_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "glue_crawler" {
  name               = "glue-cur-crawler-role"
  assume_role_policy = data.aws_iam_policy_document.glue_crawler_assume.json
}

data "aws_iam_policy_document" "glue_crawler_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.central_log_bucket_name}"]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.cur_s3_prefix}/*", "${var.cur_s3_prefix}/"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:GetObjectVersion"]
    resources = ["arn:aws:s3:::${var.central_log_bucket_name}/${var.cur_s3_prefix}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:GetDatabase", "glue:GetDatabases",
      "glue:CreateTable", "glue:UpdateTable", "glue:GetTable", "glue:GetTables",
      "glue:CreatePartition", "glue:BatchCreatePartition", "glue:UpdatePartition", "glue:GetPartition", "glue:GetPartitions"
    ]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:DescribeKey", "kms:GenerateDataKey*"]
    resources = [var.central_log_kms_key_arn]
  }
}

resource "aws_iam_role_policy" "glue_crawler" {
  role   = aws_iam_role.glue_crawler.id
  policy = data.aws_iam_policy_document.glue_crawler_policy.json
}

resource "aws_glue_crawler" "cur" {
  name          = var.cur_crawler_name
  role          = aws_iam_role.glue_crawler.arn
  database_name = aws_glue_catalog_database.cur.name
  table_prefix  = var.cur_catalog_table_prefix
  description   = "CUR parquet crawler"

  s3_target {
    path = "s3://${var.central_log_bucket_name}/${var.cur_s3_prefix}/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  recrawl_policy {
    recrawl_behavior = "CRAWL_EVERYTHING"
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
  })
}

############################################
# Replication role
############################################

data "aws_iam_policy_document" "replication_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cur_replication" {
  name               = var.replication_role_name
  assume_role_policy = data.aws_iam_policy_document.replication_assume.json
}

data "aws_iam_policy_document" "replication_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [aws_s3_bucket.cur_delivery.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectRetention",
      "s3:GetObjectLegalHold",
      "s3:GetObjectVersion"
    ]
    resources = ["${aws_s3_bucket.cur_delivery.arn}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = [
      "arn:aws:s3:::${var.central_log_bucket_name}/${var.cur_s3_prefix}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [var.central_log_kms_key_arn]
  }
}

resource "aws_iam_role_policy" "cur_replication" {
  role   = aws_iam_role.cur_replication.id
  policy = data.aws_iam_policy_document.replication_policy.json
}

############################################
# Replication configuration (ONLY when enabled)
############################################

resource "aws_s3_bucket_replication_configuration" "cur_to_central" {
  count  = var.enable_replication ? 1 : 0
  bucket = aws_s3_bucket.cur_delivery.id
  role   = aws_iam_role.cur_replication.arn

  depends_on = [aws_s3_bucket_versioning.cur_delivery]

  rule {
    id     = "cur-to-central-logs"
    status = "Enabled"

    filter {
      prefix = "${var.cur_s3_prefix}/"
    }

    delete_marker_replication {
      status = "Disabled"
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket = "arn:aws:s3:::${var.central_log_bucket_name}"

      encryption_configuration {
        replica_kms_key_id = var.central_log_kms_key_arn
      }
    }
  }
}
