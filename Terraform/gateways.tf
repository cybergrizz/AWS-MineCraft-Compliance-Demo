# gateways.tf

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "minecraft-igw"
    Project = "minecraft-nist-demo"
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name    = "minecraft-nat-eip"
    Project = "minecraft-nist-demo"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [aws_internet_gateway.internet_gateway]

  tags = {
    Name    = "minecraft-nat-gateway"
    Project = "minecraft-nist-demo"
  }
}