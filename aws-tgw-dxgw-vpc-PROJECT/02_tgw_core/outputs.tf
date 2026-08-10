output "tgw_id" {
  description = "Core TGW ID"
  value       = aws_ec2_transit_gateway.core_tgw.id
}

output "tgw_route_table_id" {
  description = "Core TGW route table ID"
  value       = aws_ec2_transit_gateway_route_table.core_tgw_rtb.id
}
