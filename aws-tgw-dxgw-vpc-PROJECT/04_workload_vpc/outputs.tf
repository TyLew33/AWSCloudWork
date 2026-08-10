output "vpc_id" {
  value = aws_vpc.workload_vpc.id
}

output "public_subnets" {
  value = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id,
  ]
}

output "public_route_table_id" {
  value = aws_route_table.public_rtb.id
}

output "igw_id" {
  value = aws_internet_gateway.igw.id
}

output "workload_inbound_sg_id" {
  value = module.security.workload_inbound_sg_id
}

output "workload_nacl_id" {
  value = module.security.workload_nacl_id
}
