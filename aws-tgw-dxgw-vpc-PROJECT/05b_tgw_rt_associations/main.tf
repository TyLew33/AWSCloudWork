data "terraform_remote_state" "tgw_core" {
  backend = "s3"
  config = {
    bucket  = var.state_bucket
    key     = "${var.state_key_prefix}/02_tgw_core/terraform.tfstate"
    region  = var.state_region
    profile = var.state_profile
  }
}

data "terraform_remote_state" "vpc_attachment" {
  backend = "s3"
  config = {
    bucket  = var.state_bucket
    key     = "${var.state_key_prefix}/05_tgw_vpc_attachment/terraform.tfstate"
    region  = var.state_region
    profile = var.state_profile
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "workload_assoc" {
  provider = aws.core

  transit_gateway_attachment_id  = data.terraform_remote_state.vpc_attachment.outputs.tgw_attachment_id
  transit_gateway_route_table_id = data.terraform_remote_state.tgw_core.outputs.tgw_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "workload_prop" {
  provider = aws.core

  transit_gateway_attachment_id  = data.terraform_remote_state.vpc_attachment.outputs.tgw_attachment_id
  transit_gateway_route_table_id = data.terraform_remote_state.tgw_core.outputs.tgw_route_table_id
}
