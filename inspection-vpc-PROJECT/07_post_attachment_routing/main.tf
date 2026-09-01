data "terraform_remote_state" "tgw_core" {
  backend = "s3"

  config = {
    bucket  = var.state_bucket
    key     = "${var.state_key_prefix}/01_tgw_core/terraform.tfstate"
    region  = var.state_region
    profile = var.state_profile
  }
}

data "terraform_remote_state" "inspection_vpc" {
  backend = "s3"

  config = {
    bucket  = var.state_bucket
    key     = "${var.state_key_prefix}/04_inspection_vpc/terraform.tfstate"
    region  = var.state_region
    profile = var.state_profile
  }
}

data "terraform_remote_state" "network_firewall" {
  backend = "s3"

  config = {
    bucket  = var.state_bucket
    key     = "${var.state_key_prefix}/05_network_firewall/terraform.tfstate"
    region  = var.state_region
    profile = var.state_profile
  }
}

data "terraform_remote_state" "tgw_attachments" {
  backend = "s3"

  config = {
    bucket  = var.state_bucket
    key     = "${var.state_key_prefix}/06_tgw_attachments/terraform.tfstate"
    region  = var.state_region
    profile = var.state_profile
  }
}

# --- TGW route table associations ---
# Prod and Dev both land in the "spoke" route table; Inspection lands in
# its own. This is what keeps Prod and Dev from ever sharing a route
# table with each other.
resource "aws_ec2_transit_gateway_route_table_association" "prod" {
  transit_gateway_attachment_id  = data.terraform_remote_state.tgw_attachments.outputs.prod_attachment_id
  transit_gateway_route_table_id = data.terraform_remote_state.tgw_core.outputs.tgw_rtb_spoke_id
}

resource "aws_ec2_transit_gateway_route_table_association" "dev" {
  transit_gateway_attachment_id  = data.terraform_remote_state.tgw_attachments.outputs.dev_attachment_id
  transit_gateway_route_table_id = data.terraform_remote_state.tgw_core.outputs.tgw_rtb_spoke_id
}

resource "aws_ec2_transit_gateway_route_table_association" "inspection" {
  transit_gateway_attachment_id  = data.terraform_remote_state.tgw_attachments.outputs.inspection_attachment_id
  transit_gateway_route_table_id = data.terraform_remote_state.tgw_core.outputs.tgw_rtb_inspection_id
}

# --- TGW static routes ---
# The only route in the spoke table: everything goes to Inspection. There
# is no route to the other spoke's CIDR here, static or propagated.
resource "aws_ec2_transit_gateway_route" "spoke_default_to_inspection" {
  transit_gateway_route_table_id = data.terraform_remote_state.tgw_core.outputs.tgw_rtb_spoke_id
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = data.terraform_remote_state.tgw_attachments.outputs.inspection_attachment_id

  depends_on = [aws_ec2_transit_gateway_route_table_association.inspection]
}

# So firewall-approved traffic can find its way back to each spoke.
resource "aws_ec2_transit_gateway_route" "inspection_to_prod" {
  transit_gateway_route_table_id = data.terraform_remote_state.tgw_core.outputs.tgw_rtb_inspection_id
  destination_cidr_block         = var.prod_vpc_cidr
  transit_gateway_attachment_id  = data.terraform_remote_state.tgw_attachments.outputs.prod_attachment_id

  depends_on = [aws_ec2_transit_gateway_route_table_association.prod]
}

resource "aws_ec2_transit_gateway_route" "inspection_to_dev" {
  transit_gateway_route_table_id = data.terraform_remote_state.tgw_core.outputs.tgw_rtb_inspection_id
  destination_cidr_block         = var.dev_vpc_cidr
  transit_gateway_attachment_id  = data.terraform_remote_state.tgw_attachments.outputs.dev_attachment_id

  depends_on = [aws_ec2_transit_gateway_route_table_association.dev]
}

# --- Inspection VPC's remaining intra-VPC routes ---
# Everything arriving from the TGW must be inspected first.
resource "aws_route" "tgw_attach_to_firewall" {
  route_table_id         = data.terraform_remote_state.inspection_vpc.outputs.tgw_attach_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = data.terraform_remote_state.network_firewall.outputs.firewall_endpoint_id
}

# Post-inspection traffic destined back to a spoke goes out via the TGW
# attachment rather than the NAT Gateway.
resource "aws_route" "firewall_to_prod_via_tgw" {
  route_table_id         = data.terraform_remote_state.inspection_vpc.outputs.firewall_route_table_id
  destination_cidr_block = var.prod_vpc_cidr
  transit_gateway_id     = data.terraform_remote_state.tgw_core.outputs.tgw_id

  depends_on = [aws_ec2_transit_gateway_route_table_association.inspection]
}

resource "aws_route" "firewall_to_dev_via_tgw" {
  route_table_id         = data.terraform_remote_state.inspection_vpc.outputs.firewall_route_table_id
  destination_cidr_block = var.dev_vpc_cidr
  transit_gateway_id     = data.terraform_remote_state.tgw_core.outputs.tgw_id

  depends_on = [aws_ec2_transit_gateway_route_table_association.inspection]
}

# Internet-return traffic for a spoke gets re-inspected instead of being
# routed straight back to the spoke.
resource "aws_route" "public_to_prod_via_firewall" {
  route_table_id         = data.terraform_remote_state.inspection_vpc.outputs.public_route_table_id
  destination_cidr_block = var.prod_vpc_cidr
  vpc_endpoint_id        = data.terraform_remote_state.network_firewall.outputs.firewall_endpoint_id
}

resource "aws_route" "public_to_dev_via_firewall" {
  route_table_id         = data.terraform_remote_state.inspection_vpc.outputs.public_route_table_id
  destination_cidr_block = var.dev_vpc_cidr
  vpc_endpoint_id        = data.terraform_remote_state.network_firewall.outputs.firewall_endpoint_id
}
