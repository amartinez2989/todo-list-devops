resource "aws_security_group" "server" {
  name        = "server"
  description = "Allow inbound traffic"
  vpc_id      = module.network.vpc_id
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "server-key" {
  key_name   = "server-key"
  public_key = tls_private_key.server.public_key_openssh

}
resource "aws_instance" "public_server" {
  count                  = var.public_server_count
  ami                    = data.aws_ami.ubuntu.id
  key_name               = aws_key_pair.server-key.key_name
  instance_type          = var.server_type
  subnet_id              = module.network.public_subnets[count.index]
  vpc_security_group_ids = [aws_security_group.server.id]

  associate_public_ip_address = var.include_ipv4
  user_data                   = file("scripts/install_jenkins.sh")

  tags = {
    Name = "jenkins_srv"
  }

}