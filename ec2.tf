data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"] # Specifies the official Amazon owner alias

  filter {
    name = "name"
    # This pattern matches standard Amazon Linux 2 HVM AMIs
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "minecrafte_server" {
  ami                  = data.aws_ami.amazon_linux_2.id
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.public.id
  iam_instance_profile = var.instance_profile

  tags = {
    Name    = "minecraft-server"
    Project = "minecraft-nist-demo"
    Role    = "gameserver"
  }
}

resource "aws_instance" "bastion" {
  ami                  = data.aws_ami.amazon_linux_2.id
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.private.id
  iam_instance_profile = var.instance_profile

  tags = {
    Name    = "bastion"
    Project = "minecraft-nist-demo"
    Role    = "management"
  }
}

