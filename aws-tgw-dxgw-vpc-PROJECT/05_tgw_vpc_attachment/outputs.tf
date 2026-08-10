output "tgw_attachment_id" {
  description = "VPC attachment ID for the workload VPC to the core TGW"
  value       = aws_ec2_transit_gateway_vpc_attachment.workload_attachment.id
}
