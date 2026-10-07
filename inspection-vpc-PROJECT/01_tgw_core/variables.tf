variable "tgw_asn" {
  description = "Amazon-side ASN for the Transit Gateway (must be unused in this account/region)"
  type        = number
  default     = 64512
}

variable "aws_profile" {
  description = "Named AWS CLI profile used to authenticate"
  type        = string
  default     = null
}

variable "aws_region" {
  description = "AWS region for this lab"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment tag applied to all resources"
  type        = string
  default     = "lab"
}

variable "project_name" {
  description = "Project name used for tagging and resource naming"
  type        = string
  default     = "inspection-vpc-project"
}
