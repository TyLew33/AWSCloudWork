# Remote state lookup - must match the backend.tf of every stage referenced below.
variable "state_bucket" {
  description = "S3 bucket holding this lab's remote state"
  type        = string
  default     = "inspection-vpc-tfstate-bucket"
}

variable "state_region" {
  description = "Region of the remote state bucket"
  type        = string
  default     = "us-east-2"
}

variable "state_profile" {
  description = "AWS CLI profile used to read remote state"
  type        = string
  default     = "default"
}

variable "state_key_prefix" {
  description = "Key prefix shared by every stage's backend.tf"
  type        = string
  default     = "inspection-vpc-project"
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
  default     = "lab"
}

variable "project_name" {
  description = "Project name used for tagging and resource naming"
  type        = string
  default     = "inspection-vpc-project"
}
