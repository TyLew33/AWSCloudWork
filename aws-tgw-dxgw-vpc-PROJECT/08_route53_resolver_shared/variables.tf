variable "resolver_rules" {
  type        = map(string)
  description = <<-EOT
    Map of friendly-name => RAM-shared Route 53 Resolver rule ID to associate
    with the workload VPC. The rules themselves and the outbound resolver
    endpoint must already exist in a central DNS account and be RAM-shared
    (and accepted) by the workload account.

    Example:
      {
        "internal_example_com" = "rslvr-rr-xxxxxxxxxxxxxxxxx"
        "dev_internal_example_com" = "rslvr-rr-yyyyyyyyyyyyyyyyy"
      }
  EOT
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

variable "workload_profile" {
  type        = string
  description = "AWS CLI profile for the workload account"
  default     = "workload"
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
