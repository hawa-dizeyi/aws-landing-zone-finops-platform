variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "logging_account_id" {
  type = string
}

variable "security_account_id" {
  type = string
}

variable "central_log_bucket_name" {
  type = string
}

variable "cloudtrail_trail_name" {
  type    = string
  default = "org-trail"
}

variable "enable_securityhub_standards" {
  type    = bool
  default = true
}

# Used by providers.tf for cross-account assumes
variable "org_account_access_role_name" {
  type    = string
  default = "OrganizationAccountAccessRole"
}

# Prefix used for CUR objects in the destination (central logs) bucket
variable "cur_s3_prefix" {
  type    = string
  default = "cur"
}

# Replication role name created in management account (Phase 3)
variable "cur_replication_role_name" {
  type    = string
  default = "cur-replication-role"
}
