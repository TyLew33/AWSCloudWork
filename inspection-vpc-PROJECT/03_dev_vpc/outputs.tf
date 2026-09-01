output "vpc_id" {
  description = "Dev VPC ID"
  value       = aws_vpc.dev.id
}

output "vpc_cidr" {
  description = "Dev VPC CIDR block"
  value       = aws_vpc.dev.cidr_block
}

output "subnet_id" {
  description = "Dev subnet ID"
  value       = aws_subnet.dev.id
}

output "route_table_id" {
  description = "Dev route table ID"
  value       = aws_route_table.dev.id
}
