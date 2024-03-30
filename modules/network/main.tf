resource "aws_vpc" "vpc" {
  cidr_block         = "192.168.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true  
}

resource "aws_subnet" "private_subnet1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "192.168.2.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-private1"
  }
}

resource "aws_subnet" "public_subnet1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "192.168.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "subnet-public1"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  depends_on = [ aws_internet_gateway.igw ]

  tags = {
    Name = "eip-coodesh"
  }
}
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet1.id

  tags = {
    Name = "nat-coodesh"
  }
  depends_on = [ aws_eip.nat_eip ]
}

resource "aws_route_table" "table_route_private" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "route_subnet_public" {
  route_table_id         = aws_vpc.vpc.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "route_subnet_private" {
  route_table_id         = aws_route_table.table_route_private.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat_gateway.id
}

resource "aws_route_table_association" "route_subnet_public" {
  subnet_id = aws_subnet.public_subnet1.id
  route_table_id = aws_vpc.vpc.default_route_table_id
}

resource "aws_route_table_association" "route_subnet_private" {
  subnet_id = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.table_route_private.id
}


/*
resource "aws_vpc_endpoint" "instance_connect" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.us-east-1.ec2-instance-connect"
  subnet_ids = [ aws_subnet.private_subnet1.id ]
  security_group_ids = var.security_group_ids
}
*/