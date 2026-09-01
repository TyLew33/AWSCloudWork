terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.45"
    }
  }

  # Intentionally no "s3" backend here: this stage creates the bucket and
  # lock table every other stage's backend depends on, so it has to keep
  # its own state locally to avoid a chicken-and-egg dependency.
}
