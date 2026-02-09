variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "org_service_access_principals" {
  type = list(string)
  default = [
    "cloudtrail.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
    "sso.amazonaws.com"
  ]
}

variable "accounts" {
  description = "Account vending definitions"
  type = map(object({
    name      = string
    email     = string
    ou        = string
    role_name = optional(string, "OrganizationAccountAccessRole")
  }))
}

variable "enable_account_vending" {
  type    = bool
  default = false
}
