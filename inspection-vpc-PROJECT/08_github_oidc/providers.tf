terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.45"
    }
  }
}

# No `profile` argument. Locally you run with AWS_PROFILE=default;
# in CI the credentials arrive as environment variables from OIDC.
provider "aws" {
  region = var.aws_region
}