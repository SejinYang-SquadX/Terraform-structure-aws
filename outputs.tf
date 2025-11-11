output "vpc_id" {
  description = "ID of the VPC created by the network module."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs for all public subnets."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs for all private subnets."
  value       = module.network.private_subnet_ids
}
