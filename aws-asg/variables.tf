variable "aws_region" {}
variable "instance_type" {}
variable "ami_id" {}

variable "subnets" {
  type = list(string)
}

variable "security_groups" {
  type = list(string)
}

variable "min_size" {}
variable "max_size" {}
variable "desired_capacity" {}