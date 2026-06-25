# =============================================================================
# ARCHITECTURAL DECISION NOTE: Public Subnets for ECS Tasks
# -----------------------------------------------------------------------------
# ECS Fargate tasks are intentionally placed in public subnets for this demo
# to avoid NAT Gateway costs (~$32/month per AZ). Security is enforced at the
# Security Group layer — tasks only accept inbound traffic from the ALB's
# Security Group ID (not from 0.0.0.0/0), making them unreachable from the
# internet directly.
#
# In a production or compliance-sensitive environment (PCI-DSS, HIPAA, SOC2),
# move ECS tasks to private subnets and route outbound traffic through a
# NAT Gateway to achieve network-level isolation (defense-in-depth).
# =============================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "${var.project}-vpc" }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "${var.project}-public-${count.index}" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "${var.project}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${var.project}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
