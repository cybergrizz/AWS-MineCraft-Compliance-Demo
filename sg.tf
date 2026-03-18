resource "aws_security_group" "minecraft_serversg" {
  name   = var.mc_server_sg_name
  vpc_id = aws_vpc.main.id


  ingress {
    from_port   = var.mc_port
    to_port     = var.mc_port
    protocol    = var.tcp
    cidr_blocks = [var.cidr_all]
  }

  ingress {
    from_port   = var.mc_port
    to_port     = var.mc_port
    protocol    = var.udp
    cidr_blocks = [var.cidr_all]
  }

  egress {
    from_port   = var.egress_all
    to_port     = var.egress_all
    protocol    = var.egress
    cidr_blocks = [var.cidr_all]
  }


  tags = {
    Name = "minecraft serversg"
  }
}

resource "aws_security_group" "bastion" {
  name   = var.bastion_sg_name
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = var.egress_all
    to_port     = var.egress_all
    protocol    = var.egress
    cidr_blocks = [var.cidr_all]
  }


  tags = {
    Name = "Bastion Sg"
  }
}
