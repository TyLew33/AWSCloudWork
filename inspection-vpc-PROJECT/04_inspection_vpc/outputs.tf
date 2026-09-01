output "vpc_id" {
  description = "Inspection VPC ID"
  value       = aws_vpc.inspection.id
}

output "igw_id" {
  description = "Inspection VPC internet gateway ID"
  value       = aws_internet_gateway.inspection.id
}

output "tgw_attach_subnet_id" {
  description = "Subnet ID for the TGW attachment"
  value       = aws_subnet.tgw_attach.id
}

output "firewall_subnet_id" {
  description = "Subnet ID for the Network Firewall endpoint"
  value       = aws_subnet.firewall.id
}

output "public_subnet_id" {
  description = "Subnet ID for the NAT Gateway"
  value       = aws_subnet.public.id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.nat.id
}

output "tgw_attach_route_table_id" {
  description = "Route table ID associated with the TGW-attachment subnet"
  value       = aws_route_table.tgw_attach.id
}

output "firewall_route_table_id" {
  description = "Route table ID associated with the firewall subnet"
  value       = aws_route_table.firewall.id
}

output "public_route_table_id" {
  description = "Route table ID associated with the public/NAT subnet"
  value       = aws_route_table.public.id
}
