resource "aws_vpc" "inspection" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-inspection-vpc"
  }
}

resource "aws_internet_gateway" "inspection" {
  vpc_id = aws_vpc.inspection.id

  tags = {
    Name = "${var.project_name}-inspection-igw"
  }
}

# Holds the TGW attachment ENI. Its default route to the Network Firewall
# endpoint is added in 07_post_attachment_routing, once the firewall
# exists - every packet arriving from the TGW must be inspected.
resource "aws_subnet" "tgw_attach" {
  vpc_id            = aws_vpc.inspection.id
  cidr_block        = var.tgw_attach_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.project_name}-inspection-tgw-attach-subnet"
  }
}

# Dedicated subnet for the AWS Network Firewall endpoint - AWS requires
# this subnet not be shared with other resource types.
resource "aws_subnet" "firewall" {
  vpc_id            = aws_vpc.inspection.id
  cidr_block        = var.firewall_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.project_name}-inspection-firewall-subnet"
  }
}

# Holds the NAT Gateway that provides internet egress for Prod/Dev traffic
# once it's passed inspection.
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.inspection.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-inspection-public-subnet"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-inspection-nat-eip"
  }

  depends_on = [aws_internet_gateway.inspection]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${var.project_name}-inspection-nat"
  }

  depends_on = [aws_internet_gateway.inspection]
}

# 0.0.0.0/0 -> Network Firewall endpoint is added in
# 07_post_attachment_routing, once the firewall exists.
resource "aws_route_table" "tgw_attach" {
  vpc_id = aws_vpc.inspection.id

  tags = {
    Name = "${var.project_name}-inspection-tgw-attach-rtb"
  }

  lifecycle {
    ignore_changes = [route]
  }
}

resource "aws_route_table_association" "tgw_attach" {
  subnet_id      = aws_subnet.tgw_attach.id
  route_table_id = aws_route_table.tgw_attach.id
}

# Default route to the NAT Gateway is set here since the NAT Gateway is
# created in this same stage. Routes back to the Prod/Dev CIDRs (for
# post-inspection traffic returning to a spoke) are added in
# 07_post_attachment_routing, once the TGW attachment exists.
resource "aws_route_table" "firewall" {
  vpc_id = aws_vpc.inspection.id

  tags = {
    Name = "${var.project_name}-inspection-firewall-rtb"
  }

  lifecycle {
    ignore_changes = [route]
  }
}

resource "aws_route" "firewall_to_nat" {
  route_table_id         = aws_route_table.firewall.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "firewall" {
  subnet_id      = aws_subnet.firewall.id
  route_table_id = aws_route_table.firewall.id
}

# Default route to the IGW is set here. Routes back to the Prod/Dev CIDRs
# (so internet-return traffic gets re-inspected by the firewall instead of
# going straight back to a spoke) are added in 07_post_attachment_routing.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.inspection.id

  tags = {
    Name = "${var.project_name}-inspection-public-rtb"
  }

  lifecycle {
    ignore_changes = [route]
  }
}

resource "aws_route" "public_to_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.inspection.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
