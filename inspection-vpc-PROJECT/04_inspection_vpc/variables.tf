variable "vpc_cidr" {
  description = "CIDR block for the Inspection VPC"
  type        = string
  default     = "10.238.0.0/24"
}

variable "tgw_attach_subnet_cidr" {
  description = "CIDR for the subnet that holds the TGW attachment ENI"
  type        = string
  default     = "10.238.0.0/28"
}

variable "firewall_subnet_cidr" {
  description = "CIDR for the dedicated AWS Network Firewall subnet"
  type        = string
  default     = "10.238.0.16/28"
}

variable "public_subnet_cidr" {
  description = "CIDR for the public/NAT subnet"
  type        = string
  default     = "10.238.0.32/28"
}

variable "availability_zone" {
  description = "Single AZ this lab deploys into (minimal-cost: no multi-AZ redundancy)"
  type        = string
  default     = "us-east-2a"
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
  default     = "inspection"
}

variable "project_name" {
  description = "Project name used for tagging and resource naming"
  type        = string
  default     = "inspection-vpc-project"
}
