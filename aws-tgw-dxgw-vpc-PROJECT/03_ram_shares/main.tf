data "aws_caller_identity" "core" {
  provider = aws.core
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

resource "aws_ram_resource_share" "tgw_share" {
  provider = aws.core

  name                      = "${var.project_name}-tgw-share"
  allow_external_principals = false

  tags = {
    Name = "${var.project_name}-tgw-share"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ram_resource_association" "tgw" {
  provider = aws.core

  resource_arn       = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.core.account_id}:transit-gateway/${data.terraform_remote_state.tgw_core.outputs.tgw_id}"
  resource_share_arn = aws_ram_resource_share.tgw_share.arn
}

resource "aws_ram_principal_association" "workload" {
  for_each = toset(var.workload_principal_account_ids)

  provider = aws.core

  principal          = each.value
  resource_share_arn = aws_ram_resource_share.tgw_share.arn
}
