provider "aws" {
  region = "eu-west-1"
}

module "vpc" {
  source = "git::https://github.com/AyoubHmadouch/terraform-aws-vpc.git?ref=master"

  name     = "eks-vpc"
  vpc_cidr = "10.0.0.0/16"
  tier     = 2
  az_count = 2
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
  tags = {
    Environment = "dev"
    Project     = "eks-sandbox"
  }
}

module "eks" {
  source = "../../"

  subnet_ids = values(module.vpc.private_subnets)[*].id

  cluster_name    = "eks-sandbox"
  cluster_version = "1.33"
  managed_node_group = {
    "default" = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      max_size       = 4
      min_size       = 1
    }
  }

  access_entries = {}

  depends_on = [module.vpc]
}
