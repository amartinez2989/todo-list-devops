output "region" {
  value = data.aws_region.current.name
}

output "azs" {
  value = data.aws_availability_zones.available.names
}

# Outputs Networks
output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of private subnets."
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of public subnets."
  value       = module.vpc.public_subnets
}
output "nat_gateway" {
  description = " NAT Gateways."
  value       = module.vpc.igw_id
}


# Outputs EKS
output "cluster_id" {
  description = "ID of the EKS cluster."
  value       = module.eks.cluster_id
}
output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint of the EKS cluster."
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version of the EKS cluster."
  value       = module.eks.cluster_version
}
output "cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = module.eks.cluster_status
}
output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster."
  value       = module.eks.cluster_security_group_id
}

output "eks_managed_node_groups" {
  description = "Map of EKS managed node groups attributes."
  value       = module.eks.eks_managed_node_groups
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for the EKS cluster."
  value       = module.eks.cloudwatch_log_group_name
}

# EC2 Jenkins
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
