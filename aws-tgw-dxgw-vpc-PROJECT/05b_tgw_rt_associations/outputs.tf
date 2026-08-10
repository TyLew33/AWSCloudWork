output "tgw_route_table_association_id" {
  description = "ID of the TGW RT association for the workload VPC attachment"
  value       = aws_ec2_transit_gateway_route_table_association.workload_assoc.id
}

output "tgw_route_table_propagation_id" {
  description = "ID of the TGW RT propagation for the workload VPC attachment"
  value       = aws_ec2_transit_gateway_route_table_propagation.workload_prop.id
}
