# routes.tf

resource "aws_route_table" "server_rtb" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.cidr_all
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name    = "minecraft-server-rtb"
    Project = "minecraft-nist-demo"
    Tier    = "public"
  }
}

resource "aws_route_table" "bastion_rtb" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = var.cidr_all
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name    = "minecraft-bastion-rtb"
    Project = "minecraft-nist-demo"
    Tier    = "private"
  }
}

resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.server_rtb.id
  subnet_id      = aws_subnet.public.id
}

resource "aws_route_table_association" "private" {
  route_table_id = aws_route_table.bastion_rtb.id
  subnet_id      = aws_subnet.private.id
}