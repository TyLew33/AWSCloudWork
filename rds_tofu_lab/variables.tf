variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "db_username" {
  type    = string
  default = "postgres"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "my_ip" {
  description = "Your public IP in CIDR format"
}
