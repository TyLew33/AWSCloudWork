# ---------------------------
# NACL
# ---------------------------
resource "aws_network_acl" "workload_nacl" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.project_name}-nacl"
  }
}

resource "aws_network_acl_rule" "in_allow_all" {
  network_acl_id = aws_network_acl.workload_nacl.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "out_allow_all" {
  network_acl_id = aws_network_acl.workload_nacl.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_association" "public_a" {
  subnet_id      = var.public_subnets[0]
  network_acl_id = aws_network_acl.workload_nacl.id
}

resource "aws_network_acl_association" "public_b" {
  subnet_id      = var.public_subnets[1]
  network_acl_id = aws_network_acl.workload_nacl.id
}

# ---------------------------
# Security Group
# ---------------------------
resource "aws_security_group" "workload_inbound" {
  name   = "${var.project_name}-inbound"
  vpc_id = var.vpc_id

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Self-reference: allow all traffic between instances using this SG.
  # Kept as an inline block (not a standalone aws_security_group_rule) to
  # avoid the inline + standalone-rule conflict that causes perpetual diffs.
  ingress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    self      = true
  }

  ingress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [var.public_ingress_cidr]
  }

  dynamic "ingress" {
    for_each = toset(var.web_ports)
    content {
      protocol    = "tcp"
      from_port   = ingress.value
      to_port     = ingress.value
      cidr_blocks = [var.public_ingress_cidr]
    }
  }

  dynamic "ingress" {
    for_each = toset(var.app_ports)
    content {
      protocol    = "tcp"
      from_port   = ingress.value
      to_port     = ingress.value
      cidr_blocks = [var.public_ingress_cidr]
    }
  }

  dynamic "ingress" {
    for_each = toset(var.nfs_cidrs)
    content {
      protocol    = "tcp"
      from_port   = 2049
      to_port     = 2049
      cidr_blocks = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = toset(var.trusted_cidrs)
    content {
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      cidr_blocks = [ingress.value]
    }
  }

  tags = {
    Name = "${var.project_name}-inbound"
  }
}
