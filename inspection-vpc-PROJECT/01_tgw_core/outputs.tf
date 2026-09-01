output "tgw_id" {
  description = "Transit Gateway ID"
  value       = aws_ec2_transit_gateway.tgw.id
}

output "tgw_rtb_spoke_id" {
  description = "TGW route table ID associated with the Prod and Dev attachments"
  value       = aws_ec2_transit_gateway_route_table.spoke.id
}

output "tgw_rtb_inspection_id" {
  description = "TGW route table ID associated with the Inspection attachment"
  value       = aws_ec2_transit_gateway_route_table.inspection.id
}
