# outputs.tf
output "minecraft_server_id" {
  value = aws_instance.minecraft_server.id
}

output "bastion_id" {
  value = aws_instance.bastion.id
}

output "nat_gateway_ip" {
  value = aws_eip.nat_eip.public_ip
}