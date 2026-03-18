resource "aws_instance" "minecraft_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name
  vpc_security_group_ids = [aws_security_group.minecraft_serversg.id]

  tags = {
    Name    = "minecraft-server"
    Project = "minecraft-nist-demo"
    Role    = "gameserver"
  }
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name
  vpc_security_group_ids = [aws_security_group.bastion.id]

  tags = {
    Name    = "bastion"
    Project = "minecraft-nist-demo"
    Role    = "management"
  }
}

