variable "workload_principal_account_ids" {
  description = "AWS account IDs to share the TGW with via RAM (e.g. [\"222222222222\"])"
  type        = list(string)
}

variable "state_bucket" {
  type        = string
  description = "S3 bucket holding remote state for this landing zone (must match backend.tf)"
  default     = "opentofu-state-bucket"
}

variable "state_region" {
  type        = string
  description = "Region of the state bucket (must match backend.tf)"
  default     = "us-east-2"
}

variable "state_profile" {
  type        = string
  description = "AWS CLI profile used to read remote state (must match backend.tf)"
  default     = "core"
}

variable "state_key_prefix" {
  type        = string
  description = "Key prefix shared by every stage's state object (must match backend.tf)"
  default     = "landing-zone/example-workload-prod"
}

variable "core_profile" {
  type        = string
  description = "AWS CLI profile for the core account"
  default     = "core"
}

variable "aws_region" {
  type        = string
  description = "AWS region the landing zone deploys into"
  default     = "us-east-2"
}

variable "environment" {
  type        = string
  description = "Environment tag value applied to every resource"
  default     = "prod"
}

variable "project_name" {
  type        = string
  description = "Project tag value / naming prefix applied to every resource"
  default     = "example-landing-zone"
}
