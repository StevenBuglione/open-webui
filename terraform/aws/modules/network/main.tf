locals {
  public_subnets = {
    for idx, cidr in var.public_subnet_cidrs :
    idx => {
      cidr_block        = cidr
      availability_zone = var.azs[idx]
    }
  }

  private_subnets = {
    for idx, cidr in var.private_subnet_cidrs :
    idx => {
      cidr_block        = cidr
      availability_zone = var.azs[idx]
    }
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name = "${var.name}-public-${each.value.availability_zone}"
  })
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone
  tags = merge(var.tags, {
    Name = "${var.name}-private-${each.value.availability_zone}"
  })
}

resource "aws_eip" "nat" {
  for_each = var.enable_nat_gateway ? aws_subnet.public : {}
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-nat-${each.value.availability_zone}"
  })
}

resource "aws_nat_gateway" "this" {
  for_each = var.enable_nat_gateway ? aws_subnet.public : {}

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id
  tags = merge(var.tags, {
    Name = "${var.name}-nat-${each.value.availability_zone}"
  })
}

resource "aws_route_table" "public" {
  for_each = aws_subnet.public

  vpc_id = aws_vpc.this.id
  tags = merge(var.tags, {
    Name = "${var.name}-public-${each.value.availability_zone}"
  })
}

resource "aws_route" "public_internet" {
  for_each               = aws_route_table.public
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[each.key].id
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.this.id
  tags = merge(var.tags, {
    Name = "${var.name}-private-${each.value.availability_zone}"
  })
}

resource "aws_route" "private_nat" {
  for_each               = var.enable_nat_gateway ? aws_route_table.private : {}
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.key].id
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
