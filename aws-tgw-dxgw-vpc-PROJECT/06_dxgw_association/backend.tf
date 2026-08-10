terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.45"
      configuration_aliases = [aws.core]
    }
  }

  backend "s3" {
    bucket         = "opentofu-state-bucket"
    key            = "landing-zone/example-workload-prod/06_dxgw_association/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "opentofu-state-lock"
    encrypt        = true
    profile        = "core"
  }
}
