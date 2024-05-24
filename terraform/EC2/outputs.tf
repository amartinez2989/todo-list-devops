output "region" {
  value = data.aws_region.current.name
}

output "azs" {
  value = data.aws_availability_zones.available.names
}

output "private_key" {
  value     = tls_private_key.server.private_key_pem
  sensitive = true
}

output "server_public_ip" {
  value = aws_instance.public_server.*.public_ip
}
output "public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.public_server.*.public_dns
}