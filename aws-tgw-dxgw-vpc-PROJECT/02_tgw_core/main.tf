# Regional Transit Gateway in the core account
resource "aws_ec2_transit_gateway" "core_tgw" {
  provider = aws.core

  amazon_side_asn                 = var.tgw_asn
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  description                     = "Regional Transit Gateway"

  tags = {
    Name = "${var.project_name}-tgw"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Explicit TGW route table (required since the defaults above are disabled)
resource "aws_ec2_transit_gateway_route_table" "core_tgw_rtb" {
  provider           = aws.core
  transit_gateway_id = aws_ec2_transit_gateway.core_tgw.id

  tags = {
    Name = "${var.project_name}-tgw-rtb"
  }

  lifecycle {
    prevent_destroy = true
  }
}
