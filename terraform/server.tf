resource "aws_security_group" "server" {
  name        = "server"
  description = "Allow inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress = [
    for port in [22, 80, 8787, 9000] : {
      description      = "inbound rules"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
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
  subnet_id              = module.vpc.public_subnets[count.index]
  vpc_security_group_ids = [aws_security_group.server.id]

  root_block_device {
    volume_size = 30
  }
  associate_public_ip_address = var.include_ipv4
  user_data                   = file("scripts/install_jenkins.sh")  
  tags = {
    Name = "jenkins_srv"
  }
  
}

# Recurso para ejecutar un comando local después de que la instancia esté creada
resource "null_resource" "wait_for_instance" {
  count = length(aws_instance.public_server)

  triggers = {
    instance_id = aws_instance.public_server[count.index].id
  }

  provisioner "local-exec" {
    command = "sleep 180"  # Espera 3 minutos para asegurarse de que la instancia esté completamente levantada
    when    = create   # Ejecuta este provisioner solo cuando se crea la instancia
  }
}

# Recurso para ejecutar comandos remotos una vez que la instancia esté completamente levantada
resource "null_resource" "output_installation_code" {
  depends_on = [null_resource.wait_for_instance]
  count = length(aws_instance.public_server)
  provisioner "remote-exec" {
    inline = [
      "echo 'Esta es la clave de instalación de Jenkins:'",
      "docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.server.private_key_pem
      host        = aws_instance.public_server[count.index].public_ip
    }
  }
}