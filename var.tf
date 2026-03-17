variable "azones" {
  type        = string
  default     = "us-east-1a"
  description = "Availabilty Zones"
}

variable "vpc_id" {
  type        = string
  default     = "aws_vpc.main.id"
  description = "Name for the Minecraft server security group"
}

variable "ami_id" {
  type    = string
  default = "data.aws_ami.amazon_linux_2.id"
}

variable "mc_port" {
  type        = number
  default     = 25565
  description = "Minecraft game port (TCP and UDP)"
}

variable "egress_all" {
  type    = number
  default = 0
}

variable "egress" {
  type    = string
  default = "-1"
}

variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "cidr_public" {
  type    = string
  default = "10.0.1.0/24"
}

variable "cidr_private" {
  type    = string
  default = "10.0.2.0/24"
}

variable "cidr_all" {
  type        = string
  default     = "0.0.0.0/0"
  description = "Open CIDR for public ingress"
}

variable "mc_server_sg_name" {
  type        = string
  default     = "Minecraft Server SG"
  description = "Name for the Minecraft server security group"
}

variable "bastion_sg_name" {
  type        = string
  default     = "Bastion SG"
  description = "Name for the Minecraft server security group"
}

variable "udp" {
  type        = string
  default     = "udp"
  description = "UDP port for sg access"
}

variable "tcp" {
  type        = string
  default     = "tcp"
  description = "TCP port for sg access"
}

variable "public_subnet" {
  type    = string
  default = "aws_subnet.public.id"
}

variable "private_subnet" {
  type    = string
  default = "aws_subnet.private.id"
}

variable "instance_type" {
  type        = string
  default     = "t3.medium"
  description = "ec2 instance type"
}

variable "tenancy" {
  type    = string
  default = "default"
}

variable "true" {
  type    = bool
  default = true
}

variable "instance_profile" {
  type    = string
  default = "minecraft_ssm_instance_role"
}
