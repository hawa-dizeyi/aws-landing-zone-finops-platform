output "cur_report_name" {
  value = aws_cur_report_definition.cur.report_name
}

output "cur_delivery_bucket_name" {
  value = aws_s3_bucket.cur_delivery.bucket
}

output "replication_role_arn" {
  value = aws_iam_role.cur_replication.arn
}

output "athena_workgroup" {
  value = aws_athena_workgroup.finops.name
}

output "glue_database" {
  value = aws_glue_catalog_database.cur.name
}
