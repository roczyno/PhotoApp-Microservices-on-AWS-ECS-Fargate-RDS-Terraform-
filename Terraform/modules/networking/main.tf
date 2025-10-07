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
  count  = 1
  domain = "vpc"

  tags = {
    Name = "${var.cluster_name}-nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = 1
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.cluster_name}-nat-${count.index + 1}"
  }
}

resource "aws_route_table" "private" {
  count  = length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.PhotoApp_VPC.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
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

resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.PhotoApp_VPC.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-alb-sg"
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.cluster_name}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.PhotoApp_VPC.id

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow inter-service communication
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-ecs-tasks-sg"
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.cluster_name}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.PhotoApp_VPC.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-rds-sg"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.cluster_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.cluster_name}-db-subnet-group"
  }
}
