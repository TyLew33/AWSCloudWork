# The TGW was created (stage 02) with default_route_table_association and
# default_route_table_propagation both disabled, so the DXGW does NOT
# auto-associate with the core TGW route table and on-prem prefixes learned
# via BGP do NOT auto-propagate into it. This stage wires both explicitly:
#
#   * association  -> traffic arriving from on-prem at the TGW consults
#                     the core TGW route table for forwarding into the VPC.
#   * propagation  -> on-prem BGP prefixes are installed into the core TGW
#                     route table so the VPC attachment can route to them.
#
# A DXGW can only be associated with one TGW route table at a time; this is
# the single shared route table the workload VPC attachment also uses.

data "terraform_remote_state" "dxgw_inputs" {
  backend = "s3"
  config = {
    bucket  = var.state_bucket
    key     = "${var.state_key_prefix}/01_dxgw_inputs/terraform.tfstate"
    region  = var.state_region
    profile = var.state_profile
  }
}

data "terraform_remote_state" "tgw_core" {
  backend = "s3"
  config = {
    bucket  = var.state_bucket
    key     = "${var.state_key_prefix}/02_tgw_core/terraform.tfstate"
    region  = var.state_region
    profile = var.state_profile
  }
}

data "terraform_remote_state" "dxgw_assoc" {
  backend = "s3"
  config = {
    bucket  = var.state_bucket
    key     = "${var.state_key_prefix}/06_dxgw_association/terraform.tfstate"
    region  = var.state_region
    profile = var.state_profile
  }
}

# Look up the implicit TGW attachment AWS creates when the DXGW association
# is established in stage 06.
data "aws_ec2_transit_gateway_dx_gateway_attachment" "dxgw" {
  provider = aws.core

  transit_gateway_id = data.terraform_remote_state.tgw_core.outputs.tgw_id
  dx_gateway_id      = data.terraform_remote_state.dxgw_inputs.outputs.dxgw_id

  depends_on = [data.terraform_remote_state.dxgw_assoc]
}

resource "aws_ec2_transit_gateway_route_table_association" "dxgw_assoc" {
  provider = aws.core

  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_dx_gateway_attachment.dxgw.id
  transit_gateway_route_table_id = data.terraform_remote_state.tgw_core.outputs.tgw_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "dxgw_prop" {
  provider = aws.core

  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_dx_gateway_attachment.dxgw.id
  transit_gateway_route_table_id = data.terraform_remote_state.tgw_core.outputs.tgw_route_table_id
}
