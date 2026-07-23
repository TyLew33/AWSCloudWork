###################################
# VPC
###################################

resource "aws_vpc" "main" {

  cidr_block = "10.0.0.0/16"

  enable_dns_support = true

  enable_dns_hostnames = true

  tags = {
    Name = "rds-lab-vpc"
  }
}


###################################
# Internet Gateway
###################################

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "rds-lab-igw"
  }
}


###################################
# Public Subnets
###################################

resource "aws_subnet" "public1" {

  vpc_id = aws_vpc.main.id

  cidr_block = "10.0.1.0/24"

  availability_zone = "us-east-2a"

  tags = {
    Name = "rds-public-a"
  }
}


resource "aws_subnet" "public2" {

  vpc_id = aws_vpc.main.id

  cidr_block = "10.0.2.0/24"

  availability_zone = "us-east-2b"

  tags = {
    Name = "rds-public-b"
  }
}


###################################
# Route Table
###################################

resource "aws_route_table" "public" {

  vpc_id = aws_vpc.main.id


  route {

    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.igw.id

  }

}


resource "aws_route_table_association" "public1" {

  subnet_id = aws_subnet.public1.id

  route_table_id = aws_route_table.public.id

}


resource "aws_route_table_association" "public2" {

  subnet_id = aws_subnet.public2.id

  route_table_id = aws_route_table.public.id

}



###################################
# Security Group
###################################

resource "aws_security_group" "postgres" {

  name = "postgres-rds-sg"

  vpc_id = aws_vpc.main.id


  ingress {

    description = "PostgreSQL access"

    from_port = 5432

    to_port = 5432

    protocol = "tcp"

    cidr_blocks = [
      var.my_ip
    ]

  }


  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]

  }

}



###################################
# RDS Subnet Group
###################################

resource "aws_db_subnet_group" "main" {

  name = "postgres-subnet-group"


  subnet_ids = [

    aws_subnet.public1.id,

    aws_subnet.public2.id

  ]


  tags = {

    Name = "postgres-subnet-group"

  }

}



###################################
# PostgreSQL RDS
###################################

resource "aws_db_instance" "postgres" {

  identifier = "postgres-lab"


  engine = "postgres"


  engine_version = "16"


  instance_class = "db.t4g.micro"


  allocated_storage = 20


  storage_type = "gp3"


  db_name = "labdb"


  username = var.db_username


  password = var.db_password


  publicly_accessible = true


  db_subnet_group_name = aws_db_subnet_group.main.name


  vpc_security_group_ids = [

    aws_security_group.postgres.id

  ]


  backup_retention_period = 0


  skip_final_snapshot = true


  deletion_protection = false


  multi_az = false

}