variable "tgw_asn" {
  type        = number
  description = "Amazon-side ASN for the regional Transit Gateway (must be unused by any other TGW/VGW in the account)"
  default     = 64512
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
