variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

# IDs from your Phase 1 org stack outputs
variable "logging_account_id" {
  type = string
}

variable "security_account_id" {
  type = string
}

# Role that exists by default in new org accounts
variable "org_account_access_role_name" {
  type    = string
  default = "OrganizationAccountAccessRole"
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
