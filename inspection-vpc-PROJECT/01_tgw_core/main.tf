# Transit Gateway. Default route table association/propagation are disabled
# so that Prod and Dev only ever get the routes we explicitly add in
# 07_post_attachment_routing — nothing is ever implicitly reachable.
resource "aws_ec2_transit_gateway" "tgw" {
  amazon_side_asn                 = var.tgw_asn
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  description                     = "${var.project_name} transit gateway"

  tags = {
    Name = "${var.project_name}-tgw"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Associated with the Prod and Dev attachments. Holds only a static
# 0.0.0.0/0 route to the Inspection attachment (added in
# 07_post_attachment_routing) - Prod and Dev never get a route to each
# other's CIDR from this table.
resource "aws_ec2_transit_gateway_route_table" "spoke" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id

  tags = {
    Name = "${var.project_name}-tgw-rtb-spoke"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Associated with the Inspection attachment. Holds static routes back to
# the Prod and Dev CIDRs (added in 07_post_attachment_routing) so
# firewall-approved traffic can find its way back to the right spoke.
resource "aws_ec2_transit_gateway_route_table" "inspection" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id

  tags = {
    Name = "${var.project_name}-tgw-rtb-inspection"
  }

  lifecycle {
    prevent_destroy = true
  }
}
