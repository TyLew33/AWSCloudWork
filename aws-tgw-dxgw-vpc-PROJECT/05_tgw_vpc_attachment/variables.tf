variable "on_prem_cidrs" {
  type        = list(string)
  description = "On-prem CIDR ranges routed to the TGW from the public subnet(s)"
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
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
