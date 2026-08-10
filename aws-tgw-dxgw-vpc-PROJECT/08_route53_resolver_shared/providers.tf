provider "aws" {
  alias   = "workload"
  profile = var.workload_profile
  region  = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "OpenTofu"
    }
  }
}
