terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.45"
    }
  }

  backend "s3" {
    bucket         = "inspection-vpc-tfstate-bucket"
    key            = "inspection-vpc-project/02_prod_vpc/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "inspection-vpc-tfstate-lock"
    encrypt        = true
  }
}
