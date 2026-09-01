variable "vpc_cidr" {
  description = "CIDR block for the Dev VPC"
  type        = string
  default     = "10.232.0.0/24"
}

variable "availability_zone" {
  description = "Single AZ this lab deploys into (minimal-cost: no multi-AZ redundancy)"
  type        = string
  default     = "us-east-2a"
}

variable "aws_profile" {
  description = "Named AWS CLI profile used to authenticate"
  type        = string
  default     = "default"
}

variable "aws_region" {
  description = "AWS region for this lab"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment tag applied to all resources"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for tagging and resource naming"
  type        = string
  default     = "inspection-vpc-project"
}
