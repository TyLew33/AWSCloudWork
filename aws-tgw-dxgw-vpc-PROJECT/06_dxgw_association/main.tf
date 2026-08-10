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

# Assumes the DXGW is owned by the core account. If it lives in a different
# account, split this into the proposal/accepter pattern instead.
resource "aws_dx_gateway_association" "tgw_dxgw_assoc" {
  provider = aws.core

  dx_gateway_id         = data.terraform_remote_state.dxgw_inputs.outputs.dxgw_id
  associated_gateway_id = data.terraform_remote_state.tgw_core.outputs.tgw_id
  allowed_prefixes      = data.terraform_remote_state.dxgw_inputs.outputs.allowed_prefixes

  lifecycle {
    prevent_destroy = true
  }
}
