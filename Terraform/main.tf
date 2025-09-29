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

