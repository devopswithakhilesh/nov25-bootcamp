# VPC -> "10.0.0.0/16"

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "nov25"
  }
}

#  resouce_type.resource_name.<return attributes>
# aws_vpc.main.id
# internet gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "nov25"
  }
}
# elastic IP -2 

resource "aws_eip" "one" {
  tags = {
    Name = "nov25-eip-1"
  }
}

resource "aws_eip" "two" {
  tags = {
    Name = "nov25-eip-1"
  }
}



# private subnets - 2

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
}
resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1b"
}


# route tables -1
# routes to nat gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat1.id
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat1.id
  }

  tags = {
    Name = "private"
  }
}
# attach route tables to private subnets

resource "aws_route_table_association" "pri_a" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "pri_b" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
}







# Public subnets

# public subnets - 2
resource "aws_subnet" "public1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-south-1a"
}
resource "aws_subnet" "public2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-south-1b"
}

# route tables -1
# routes to internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "public"
  }
}
# attach route tables to public subnets
resource "aws_route_table_association" "pub_a" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "pub_b" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}


# Nat gateway
resource "aws_nat_gateway" "nat1" {
  # implict dependency on eip resource
  allocation_id = aws_eip.one.id
  subnet_id     = aws_subnet.public1.id

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "nat2" {
  # implict dependency on eip resource
  allocation_id = aws_eip.two.id
  subnet_id     = aws_subnet.public2.id

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

# database private subnets -2

resource "aws_subnet" "rds1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "nov25-db-subnet-1"
  }
}

resource "aws_subnet" "rds2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "nov25-db-subnet-2"
  }
}