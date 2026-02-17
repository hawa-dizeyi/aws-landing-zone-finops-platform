variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

# Central logging bucket (Logging account) from Phase 2
variable "central_log_bucket_name" {
  type = string
}

# KMS key in Logging account used by the central bucket (Phase 2 output)
variable "central_log_kms_key_arn" {
  type = string
}

# Logging account ID (member account)
variable "logging_account_id" {
  type = string
}

# CUR delivery bucket (must be in the management/payer account)
variable "cur_delivery_bucket_name" {
  type = string
}

# CUR delivery prefix
variable "cur_s3_prefix" {
  type    = string
  default = "cur"
}

variable "cur_report_name" {
  type    = string
  default = "org-cur"
}

# Athena query results prefix (we store results in the central logs bucket)
variable "athena_results_prefix" {
  type    = string
  default = "athena-results"
}

variable "glue_database_name" {
  type    = string
  default = "cur_db"
}

variable "athena_workgroup_name" {
  type    = string
  default = "finops"
}

variable "replication_role_name" {
  type    = string
  default = "cur-replication-role"
}

# Two-step enablement:
# - First apply with false (creates role + CUR bucket + CUR report)
# - After security stack allows the role, set true and apply again to create replication config
variable "enable_replication" {
  type    = bool
  default = false
}
