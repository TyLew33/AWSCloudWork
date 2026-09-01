variable "state_bucket_name" {
  description = "Name of the S3 bucket every later stage's backend.tf points at (must be globally unique)"
  type        = string
  default     = "inspection-vpc-tfstate-bucket"
}

variable "state_lock_table_name" {
  description = "Name of the DynamoDB table used for state locking by every later stage"
  type        = string
  default     = "inspection-vpc-tfstate-lock"
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
  default     = "project"
}

variable "project_name" {
  description = "Project name used for tagging and resource naming"
  type        = string
  default     = "inspection-vpc-project"
}
