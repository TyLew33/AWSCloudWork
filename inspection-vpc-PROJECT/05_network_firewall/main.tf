data "terraform_remote_state" "inspection_vpc" {
  backend = "s3"

  config = {
    bucket  = var.state_bucket
    key     = "${var.state_key_prefix}/04_inspection_vpc/terraform.tfstate"
    region  = var.state_region
    profile = var.state_profile
  }
}

# The only policy this lab enforces: explicitly drop traffic between Prod
# and Dev in both directions. Using DEFAULT_ACTION_ORDER (the classic
# 5-tuple engine) means anything that doesn't match a DROP rule here is
# implicitly allowed, so internet-bound traffic needs no separate "allow"
# rule.
resource "aws_networkfirewall_rule_group" "block_prod_dev" {
  name     = "${var.project_name}-block-prod-dev"
  type     = "STATEFUL"
  capacity = 100

  rule_group {
    rules_source {
      stateful_rule {
        action = "DROP"

        header {
          protocol         = "IP"
          source           = var.prod_cidr
          source_port      = "ANY"
          destination      = var.dev_cidr
          destination_port = "ANY"
          direction        = "FORWARD"
        }

        rule_option {
          keyword = "sid:1"
        }
      }

      stateful_rule {
        action = "DROP"

        header {
          protocol         = "IP"
          source           = var.dev_cidr
          source_port      = "ANY"
          destination      = var.prod_cidr
          destination_port = "ANY"
          direction        = "FORWARD"
        }

        rule_option {
          keyword = "sid:2"
        }
      }
    }
  }

  tags = {
    Name = "${var.project_name}-block-prod-dev"
  }
}

resource "aws_networkfirewall_firewall_policy" "main" {
  name = "${var.project_name}-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.block_prod_dev.arn
    }
  }

  tags = {
    Name = "${var.project_name}-policy"
  }
}

resource "aws_networkfirewall_firewall" "main" {
  name                = "${var.project_name}-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.main.arn
  vpc_id              = data.terraform_remote_state.inspection_vpc.outputs.vpc_id

  subnet_mapping {
    subnet_id = data.terraform_remote_state.inspection_vpc.outputs.firewall_subnet_id
  }

  tags = {
    Name = "${var.project_name}-firewall"
  }
}

# Network Firewall logs nothing by default. ALERT captures every stateful
# rule match that isn't a plain Pass - including our DROP rules, which is
# what "review the firewall logs" actually depends on. FLOW captures every
# connection the firewall saw (useful to confirm the internet-bound path
# is actually being inspected). Short retention keeps this at effectively
# zero cost for a lab.
resource "aws_cloudwatch_log_group" "alert" {
  name              = "/aws/networkfirewall/${var.project_name}/alert"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-firewall-alert-logs"
  }
}

resource "aws_cloudwatch_log_group" "flow" {
  name              = "/aws/networkfirewall/${var.project_name}/flow"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-firewall-flow-logs"
  }
}

resource "aws_networkfirewall_logging_configuration" "main" {
  firewall_arn = aws_networkfirewall_firewall.main.arn

  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.alert.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }

    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.flow.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }
  }
}
