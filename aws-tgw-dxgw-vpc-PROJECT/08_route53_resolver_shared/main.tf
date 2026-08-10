data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket  = var.state_bucket
    key     = "${var.state_key_prefix}/04_workload_vpc/terraform.tfstate"
    region  = var.state_region
    profile = var.state_profile
  }
}

resource "aws_route53_resolver_rule_association" "shared_resolvers" {
  for_each = var.resolver_rules

  provider = aws.workload

  resolver_rule_id = each.value
  vpc_id           = data.terraform_remote_state.vpc.outputs.vpc_id
  name             = "assoc-${replace(each.key, "_", "-")}-${var.project_name}-${var.environment}"
}
