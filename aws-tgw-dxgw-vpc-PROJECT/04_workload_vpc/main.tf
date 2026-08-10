# ---------------------------
# VPC
# ---------------------------
resource "aws_vpc" "workload_vpc" {
  provider   = aws.workload
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.project_name}-vpc"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# ---------------------------
# Internet Gateway
# ---------------------------
resource "aws_internet_gateway" "igw" {
  provider = aws.workload
  vpc_id   = aws_vpc.workload_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ---------------------------
# Public Subnets
# ---------------------------
resource "aws_subnet" "public_a" {
  provider                = aws.workload
  vpc_id                  = aws_vpc.workload_vpc.id
  cidr_block              = var.subnet_a_cidr
  availability_zone       = var.az_a
  map_public_ip_on_launch = true

  tags = { Name = "${var.project_name}-subnet-a" }
}

resource "aws_subnet" "public_b" {
  provider                = aws.workload
  vpc_id                  = aws_vpc.workload_vpc.id
  cidr_block              = var.subnet_b_cidr
  availability_zone       = var.az_b
  map_public_ip_on_launch = true

  tags = { Name = "${var.project_name}-subnet-b" }
}

# ---------------------------
# Public Route Table
# ---------------------------
resource "aws_route_table" "public_rtb" {
  provider = aws.workload
  vpc_id   = aws_vpc.workload_vpc.id

  # Routes are managed as standalone aws_route resources — the IGW routes
  # below, plus the on-prem TGW routes added in stage 05. Inline `route`
  # blocks cannot be mixed with aws_route on the same table.
  tags = { Name = "${var.project_name}-public-rtb" }
}

# Internet-bound routes: default plus any additional public ranges
resource "aws_route" "public_to_igw" {
  for_each = toset(concat(["0.0.0.0/0"], var.additional_internet_egress_cidrs))

  provider               = aws.workload
  route_table_id         = aws_route_table.public_rtb.id
  destination_cidr_block = each.value
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_a" {
  provider       = aws.workload
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rtb.id
}

resource "aws_route_table_association" "public_b" {
  provider       = aws.workload
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rtb.id
}

# ---------------------------
# Security (NACL + SG) child module
# ---------------------------
module "security" {
  source = "../04_security"

  providers = {
    aws = aws.workload
  }

  vpc_id       = aws_vpc.workload_vpc.id
  project_name = var.project_name

  public_subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id,
  ]
}
