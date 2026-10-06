variable "aws_region" {
  type        = string
  description = "Region holding the inspection-vpc state bucket and lock table"
  default     = "us-east-2"
}

variable "github_repository" {
  type        = string
  description = "owner/repo exactly as GitHub shows it"
  default     = "TyLew33/AWSCloudWork"
}

variable "default_branch" {
  type        = string
  description = "Branch allowed to assume the plan role for manual and drift runs"
  default     = "main"
}

variable "apply_environment" {
  type        = string
  description = "GitHub environment name that gates tofu apply for this project"
  default     = "inspection-vpc"
}

variable "state_bucket" {
  type        = string
  description = "S3 bucket created by 00_bootstrap"
  default     = "inspection-vpc-tfstate-bucket"
}

variable "state_lock_table" {
  type        = string
  description = "DynamoDB lock table created by 00_bootstrap"
  default     = "inspection-vpc-tfstate-lock"
}

variable "sub_claim_prefix" {
  type        = string
  description = <<-DESC
    Override the OIDC subject prefix GitHub stamps on tokens for this repo.
    Leave null for the classic "repo:OWNER/REPO" format. Set it to the
    sub_claim_prefix value returned by:
      gh api /repos/OWNER/REPO/actions/oidc/customization/sub
    if that endpoint reports use_immutable_subject: true.
  DESC
  default     = null
}
