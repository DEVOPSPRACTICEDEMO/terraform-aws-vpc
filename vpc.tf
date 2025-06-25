# roboshop-dev-vpc
resource "aws_vpc" "main" {
    cidr_block = var.cidr_block
    enable_dns_hostnames = true
    instance_tenancy = "default"

    tags = merge(
        var.vpc_tags,
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}-vpc"
        }
    )  
}

# IGW roboshop-dev
resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id # associate the internet gateway with the VPC

    tags = merge(
        var.igw_tags,
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}-igw"
        }
    )
  
}

# roboshop-dev-us-east-1a
resource "aws_subnet" "public" {
    count = length(var.public_subnet_cidr)
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidr[count.index]
    availability_zone = local.az_names[count.index]
    map_public_ip_on_launch = true

    tags = merge(
        var.public_subnet_tags,
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}-public-${local.az_names[count.index]}"
        }
    )
  
}

resource "aws_subnet" "private" {
    count = length(var.private_subnet_cidr)
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidr[count.index]
    availability_zone = local.az_names[count.index]
    

    tags = merge(
        var.private_subnet_tags,
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}-private-${local.az_names[count.index]}"
        }
    )
  
}

resource "aws_subnet" "database" {
    count = length(var.database_subnet_cidr)
    vpc_id = aws_vpc.main.id
    cidr_block = var.database_subnet_cidr[count.index]
    availability_zone = local.az_names[count.index]
    

    tags = merge(
        var.database_subnet_tags,
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}-datebase-${local.az_names[count.index]}"
        }
    )
  
}

resource "aws_eip" "nat" {
    domain = "vpc"
    tags = merge(
        var.eip_tags,
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}-nat-eip"
        }
    )
}

resource "aws_nat_gateway" "main" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.public[0].id # Use the first public subnet for the NAT gateway

    tags = merge(
        var.nat_gatway_tags,
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}-nat-gateway"
        }
    )

    depends_on = [aws_internet_gateway.main] # Ensure the IGW is created before the NAT gateway
  
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    tags = merge(
        var.public_route_table_tags,
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}-public-route-table"
        }
    )
  
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    tags = merge(
        var.private_route_table_tags,
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}-private-route-table"
        }
    )
  
}

resource "aws_route_table" "database" {
    vpc_id = aws_vpc.main.id

    tags = merge(
        var.database_route_table_tags,
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}-database-route-table"
        }
    )
  
}

resource "aws_route" "public" {
    route_table_id = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
}

resource "aws_route" "private" {
    route_table_id = aws_route_table.private.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
}

resource "aws_route" "database" {
    route_table_id = aws_route_table.database.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
}

resource "aws_route_table_association" "public" {
    count = length(var.public_subnet_cidr)
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
  
}

resource "aws_route_table_association" "private" {
    count = length(var.private_subnet_cidr)
    subnet_id = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private.id
  
}

resource "aws_route_table_association" "database" {
    count = length(var.database_subnet_cidr)
    subnet_id = aws_subnet.database[count.index].id
    route_table_id = aws_route_table.database.id
  
}

