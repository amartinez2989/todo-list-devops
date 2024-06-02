module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "network-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.4.0/24", "10.0.5.0/24"]


  create_igw         = true
  enable_nat_gateway = true
  single_nat_gateway = true

  enable_vpn_gateway = false

  tags = {
    Terraform   = "network"
    Environment = "dev"
  }
}