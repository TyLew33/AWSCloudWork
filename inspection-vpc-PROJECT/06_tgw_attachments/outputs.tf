output "prod_attachment_id" {
  description = "TGW attachment ID for the Prod VPC"
  value       = aws_ec2_transit_gateway_vpc_attachment.prod.id
}

output "dev_attachment_id" {
  description = "TGW attachment ID for the Dev VPC"
  value       = aws_ec2_transit_gateway_vpc_attachment.dev.id
}

output "inspection_attachment_id" {
  description = "TGW attachment ID for the Inspection VPC"
  value       = aws_ec2_transit_gateway_vpc_attachment.inspection.id
}
