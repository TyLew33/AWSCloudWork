data "terraform_remote_state" "tgw_core" {
  backend = "s3"
  config = {
    bucket  = var.state_bucket
    key     = "${var.state_key_prefix}/02_tgw_core/terraform.tfstate"
    region  = var.state_region
    profile = var.state_profile
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket  = var.state_bucket
    key     = "${var.state_key_prefix}/04_workload_vpc/terraform.tfstate"
    region  = var.state_region
    profile = var.state_profile
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "workload_attachment" {
  provider = aws.workload

  subnet_ids         = data.terraform_remote_state.vpc.outputs.public_subnets
  transit_gateway_id = data.terraform_remote_state.tgw_core.outputs.tgw_id
  vpc_id             = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name = "${var.project_name}-tgw-attachment"
  }
}

# TGW route table association + propagation are NOT created here: the TGW
# route table is owned by the core account and is not RAM-shareable, so they
# must be created from a core-profile stage. See 05b_tgw_rt_associations.
#
# resource "aws_ec2_transit_gateway_route_table_association" "workload_assoc" {
#   provider                       = aws.workload
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.workload_attachment.id
#   transit_gateway_route_table_id = data.terraform_remote_state.tgw_core.outputs.tgw_route_table_id
# }
#
# resource "aws_ec2_transit_gateway_route_table_propagation" "workload_prop" {
#   provider                       = aws.workload
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.workload_attachment.id
#   transit_gateway_route_table_id = data.terraform_remote_state.tgw_core.outputs.tgw_route_table_id
# }

# Note: the attachment lands in `pendingAcceptance` unless
# `auto_accept_shared_attachments = "enable"` is set on the TGW; otherwise
# an owner-side accept is required before downstream resources will work.

resource "aws_route" "public_to_tgw" {
  for_each = toset(var.on_prem_cidrs)

  provider = aws.workload

  route_table_id         = data.terraform_remote_state.vpc.outputs.public_route_table_id
  destination_cidr_block = each.value
  transit_gateway_id     = data.terraform_remote_state.tgw_core.outputs.tgw_id
}
