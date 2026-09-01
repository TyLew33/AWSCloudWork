data "terraform_remote_state" "tgw_core" {
  backend = "s3"

  config = {
    bucket  = var.state_bucket
    key     = "${var.state_key_prefix}/01_tgw_core/terraform.tfstate"
    region  = var.state_region
    profile = var.state_profile
  }
}

data "terraform_remote_state" "prod_vpc" {
  backend = "s3"

  config = {
    bucket  = var.state_bucket
    key     = "${var.state_key_prefix}/02_prod_vpc/terraform.tfstate"
    region  = var.state_region
    profile = var.state_profile
  }
}

data "terraform_remote_state" "dev_vpc" {
  backend = "s3"

  config = {
    bucket  = var.state_bucket
    key     = "${var.state_key_prefix}/03_dev_vpc/terraform.tfstate"
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

# Association/propagation are handled explicitly in
# 07_post_attachment_routing, not by the TGW defaults (disabled in
# 01_tgw_core).
resource "aws_ec2_transit_gateway_vpc_attachment" "prod" {
  transit_gateway_id                              = data.terraform_remote_state.tgw_core.outputs.tgw_id
  vpc_id                                          = data.terraform_remote_state.prod_vpc.outputs.vpc_id
  subnet_ids                                      = [data.terraform_remote_state.prod_vpc.outputs.subnet_id]
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "${var.project_name}-prod-attachment"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "dev" {
  transit_gateway_id                              = data.terraform_remote_state.tgw_core.outputs.tgw_id
  vpc_id                                          = data.terraform_remote_state.dev_vpc.outputs.vpc_id
  subnet_ids                                      = [data.terraform_remote_state.dev_vpc.outputs.subnet_id]
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "${var.project_name}-dev-attachment"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "inspection" {
  transit_gateway_id                              = data.terraform_remote_state.tgw_core.outputs.tgw_id
  vpc_id                                          = data.terraform_remote_state.inspection_vpc.outputs.vpc_id
  subnet_ids                                      = [data.terraform_remote_state.inspection_vpc.outputs.tgw_attach_subnet_id]
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "${var.project_name}-inspection-attachment"
  }
}

# Each spoke sends everything to the TGW - the TGW route table
# (07_post_attachment_routing) decides where it actually goes.
resource "aws_route" "prod_to_tgw" {
  route_table_id         = data.terraform_remote_state.prod_vpc.outputs.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = data.terraform_remote_state.tgw_core.outputs.tgw_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.prod]
}

resource "aws_route" "dev_to_tgw" {
  route_table_id         = data.terraform_remote_state.dev_vpc.outputs.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = data.terraform_remote_state.tgw_core.outputs.tgw_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.dev]
}
