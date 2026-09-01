resource "aws_vpc" "prod" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-prod-vpc"
  }
}

# Single subnet spans the whole VPC CIDR - this lab has no workload
# resources that need segmentation, so a dedicated TGW-attachment subnet
# isn't warranted at this scale.
resource "aws_subnet" "prod" {
  vpc_id            = aws_vpc.prod.id
  cidr_block        = var.vpc_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.project_name}-prod-subnet"
  }
}

resource "aws_route_table" "prod" {
  vpc_id = aws_vpc.prod.id

  tags = {
    Name = "${var.project_name}-prod-rtb"
  }

  # The 0.0.0.0/0 -> Transit Gateway route is added by 06_tgw_attachments,
  # once the TGW attachment this route table needs to point at actually
  # exists.
  lifecycle {
    ignore_changes = [route]
  }
}

resource "aws_route_table_association" "prod" {
  subnet_id      = aws_subnet.prod.id
  route_table_id = aws_route_table.prod.id
}
