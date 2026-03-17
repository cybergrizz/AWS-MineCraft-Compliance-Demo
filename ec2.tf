resource "aws_instance" "minecrafte_server" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  subnet_id            = var.public_subnet
  iam_instance_profile = var.instance_profile

  tags = {
    Name    = "minecraft-server"
    Project = "minecraft-nist-demo"
    Role    = "gameserver"
  }
}

resource "aws_instance" "bastion" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  subnet_id            = var.private_subnet
  iam_instance_profile = var.instance_profile

  tags = {
    Name    = "bastion"
    Project = "minecraft-nist-demo"
    Role    = "management"
  }
}

