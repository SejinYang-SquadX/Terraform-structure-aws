# -------------------- 서브넷 리스트 가공 --------------------
locals {
  public_subnets = {
    for idx, subnet in var.public_subnets :
    format("%02d", idx + 1) => subnet
  }

  private_subnets = {
    for idx, subnet in var.private_subnets :
    format("%02d", idx + 1) => subnet
  }

  first_public_subnet_key = length(local.public_subnets) > 0 ? sort(keys(local.public_subnets))[0] : null

  create_nat_gateway = var.nat_gateway_enabled && length(local.public_subnets) > 0 && length(local.private_subnets) > 0
}

# -------------------- VPC 본체 --------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}

# -------------------- 인터넷 게이트웨이 --------------------
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

# -------------------- 퍼블릭 서브넷 --------------------
resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name}-public-${each.key}"
    Tier = "public"
  })
}

# -------------------- 프라이빗 서브넷 --------------------
resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = "${var.name}-private-${each.key}"
    Tier = "private"
  })
}

# -------------------- 퍼블릭 라우팅 --------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
    Tier = "public"
  })
}

# 기본 라우트: IGW 통해 0.0.0.0/0
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# 퍼블릭 서브넷 ↔ 퍼블릭 RT 연결
resource "aws_route_table_association" "public" {
  for_each = local.public_subnets

  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[each.key].id
}

# -------------------- NAT Gateway 구성 --------------------
resource "aws_eip" "nat" {
  count  = local.create_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-nat-eip"
  })
}

# EIP를 사용하는 NAT Gateway
resource "aws_nat_gateway" "this" {
  count = local.create_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[local.first_public_subnet_key].id

  tags = merge(var.tags, {
    Name = "${var.name}-nat-gw"
  })

  depends_on = [aws_internet_gateway.this]
}

# -------------------- 프라이빗 라우팅 --------------------
resource "aws_route_table" "private" {
  for_each = local.private_subnets

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-private-rt-${each.key}"
    Tier = "private"
  })
}

# 프라이빗 라우트 테이블에 NAT 경로 추가
resource "aws_route" "private_nat" {
  for_each = local.create_nat_gateway ? local.private_subnets : {}

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

# 프라이빗 서브넷 ↔ 전용 RT 연결
resource "aws_route_table_association" "private" {
  for_each = local.private_subnets

  route_table_id = aws_route_table.private[each.key].id
  subnet_id      = aws_subnet.private[each.key].id
}
