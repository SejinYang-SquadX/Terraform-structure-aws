provider "aws" {
  region = var.aws_region
}

module "network" {
  source = "./modules/vpc"

  name                = var.project_name
  vpc_cidr            = var.vpc_cidr
  public_subnets      = var.public_subnets
  private_subnets     = var.private_subnets
  nat_gateway_enabled = var.nat_gateway_enabled
  tags                = var.tags
}
