variable "dxgw_id" {
  type        = string
  description = "Existing Direct Connect Gateway ID this landing zone associates with"
}

variable "allowed_prefixes" {
  type        = list(string)
  description = "On-prem CIDR prefixes allowed via the DXGW association"
}

variable "core_profile" {
  type        = string
  description = "AWS CLI profile for the core account (owns the TGW, DXGW, RAM share, and all remote state)"
  default     = "core"
}

variable "aws_region" {
  type        = string
  description = "AWS region the workload landing zone deploys into"
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
