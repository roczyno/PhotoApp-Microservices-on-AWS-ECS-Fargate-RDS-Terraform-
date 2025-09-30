provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "PhotoApp_VPC" {
  cidr_block = var.vpc_cidr
  tags = {
      Name = "${var.cluster_name}-vpc"
  }
}

data "aws_availability_zones" "available" {
    state = "available"
}


resource "aws_subnet" "public" {
    count = length(data.aws_availability_zones.available.names)
    vpc_id = aws_vpc.PhotoApp_VPC.id
    availability_zone = data.aws_availability_zones.available.names[count.index]
    map_public_ip_on_launch = true
    cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
    tags = {
        Name = "${var.cluster_name}-public-subnet-${count.index + 1}"
    }
  
}

resource "aws_subnet" "private" {
    count = length(data.aws_availability_zones.available.names)
    vpc_id = aws_vpc.PhotoApp_VPC.id
    availability_zone = data.aws_availability_zones.available.names[count.index]
    map_public_ip_on_launch = false
    cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
    tags = {
        Name = "${var.cluster_name}-private-subnet-${count.index + 1}"
    }
}


resource "aws_internet_gateway" "PhotoApp_IGW" {
    vpc_id = aws_vpc.PhotoApp_VPC.id
    tags = {
        Name = "${var.cluster_name}-igw"
    }
  
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.PhotoApp_VPC.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.PhotoApp_IGW.id
    }

    tags = {
        Name = "${var.cluster_name}-public-route-table"
    }
}

resource "aws_route_table_association" "public" {
    count = length(aws_subnet.public)
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}


resource "aws_eip" "nat" {
  count  = length(data.aws_availability_zones.available.names)
  domain = "vpc"

  tags = {
    Name = "${var.cluster_name}-nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = length(data.aws_availability_zones.available.names)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.cluster_name}-nat-${count.index + 1}"
  }
}

resource "aws_route_table" "private" {
  count  = length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.PhotoApp_VPC.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.cluster_name}-private-rt-${count.index + 1}"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}





