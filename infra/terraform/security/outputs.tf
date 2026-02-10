output "central_log_bucket_name" {
  value = aws_s3_bucket.central_logs.bucket
}

output "central_log_kms_key_arn" {
  value = aws_kms_key.log_bucket.arn
}

output "org_trail_arn" {
  value = aws_cloudtrail.org_trail.arn
}

output "guardduty_admin_account" {
  value = aws_guardduty_organization_admin_account.admin.admin_account_id
}

output "securityhub_admin_account" {
  value = aws_securityhub_organization_admin_account.admin.admin_account_id
}
