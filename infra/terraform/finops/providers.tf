provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "cur"
  region = "us-east-1"
}
