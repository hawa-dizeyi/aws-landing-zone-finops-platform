output "organization_id" {
  value = aws_organizations_organization.this.id
}

output "ou_ids" {
  value = local.ou_ids
}

output "account_ids" {
  value = { for k, v in aws_organizations_account.accounts : k => v.id }
}
