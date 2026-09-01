output "vpc_id" {
  description = "Prod VPC ID"
  value       = aws_vpc.prod.id
}

output "vpc_cidr" {
  description = "Prod VPC CIDR block"
  value       = aws_vpc.prod.cidr_block
}

output "subnet_id" {
  description = "Prod subnet ID"
  value       = aws_subnet.prod.id
}

output "route_table_id" {
  description = "Prod route table ID"
  value       = aws_route_table.prod.id
}
