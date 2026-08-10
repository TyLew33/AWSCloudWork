variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the workload VPC"
  default     = "10.0.0.0/22"
}

variable "subnet_a_cidr" {
  type        = string
  description = "CIDR block for the first public subnet"
  default     = "10.0.0.0/24"
}

variable "subnet_b_cidr" {
  type        = string
  description = "CIDR block for the second public subnet (e.g. a DR/second-AZ subnet)"
  default     = "10.0.1.0/24"
}

variable "az_a" {
  type        = string
  description = "Availability zone for the first public subnet"
  default     = "us-east-2a"
}

variable "az_b" {
  type        = string
  description = "Availability zone for the second public subnet"
  default     = "us-east-2b"
}

variable "additional_internet_egress_cidrs" {
  type        = list(string)
  description = "Extra CIDRs (beyond 0.0.0.0/0) routed to the IGW — useful if you need explicit routes for specific public ranges"
  default     = []
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
