provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "logging"
  region = var.aws_region

  assume_role {
    role_arn = "arn:aws:iam::${var.logging_account_id}:role/${var.org_account_access_role_name}"
  }
}

provider "aws" {
  alias  = "security"
  region = var.aws_region

  assume_role {
    role_arn = "arn:aws:iam::${var.security_account_id}:role/${var.org_account_access_role_name}"
  }
}
