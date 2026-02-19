variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "central_log_bucket_name" {
  type = string
}

variable "central_log_kms_key_arn" {
  type = string
}

variable "logging_account_id" {
  type = string
}

variable "cur_delivery_bucket_name" {
  type = string
}

variable "cur_s3_prefix" {
  type    = string
  default = "cur"
}

variable "cur_report_name" {
  type    = string
  default = "org-cur"
}

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

variable "enable_replication" {
  type    = bool
  default = false
}

variable "cur_crawler_name" {
  type    = string
  default = "cur-parquet-crawler"
}

variable "cur_catalog_table_prefix" {
  type    = string
  default = "cur_"
}
