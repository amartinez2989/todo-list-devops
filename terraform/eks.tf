module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0" # Va a hacer upgrade solamente de la versión 20

  cluster_name    = "cf_devOps-eks"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }
  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true


  eks_managed_node_groups = {
    node_cf = {
      min_size     = 1
      max_size     = 4  # Aumenta el número máximo de nodos
      desired_size = 3  # Ajusta el número deseado de nodos

      instance_types = ["t2.micro"]
      capacity_type  = "SPOT"
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}