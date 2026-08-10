provider "aws" {
  alias   = "core"
  profile = var.core_profile
  region  = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "OpenTofu"
    }
  }
}
