resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  instance_tenancy     = var.tenancy
  enable_dns_hostnames = var.true
  enable_dns_support   = var.true

  tags = {
    Name    = "minecraft-nist-vpc"
    Project = "minecraft-nist-demo"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.cidr_public
  availability_zone       = var.azones
  map_public_ip_on_launch = true

  tags = {
    Name    = "minecraft-public-subnet"
    Project = "minecraft-nist-demo"
    Tier    = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.cidr_private
  availability_zone = var.azones

  tags = {
    Name    = "minecraft-private-subnet"
    Project = "minecraft-nist-demo"
    Tier    = "private"
  }
}
