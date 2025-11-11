variable "name" {
  description = "Prefix used to build resource names."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block to assign to the VPC."
  type        = string
}

variable "public_subnets" {
  description = "Public subnet definitions including CIDR block and AZ."
  type = list(object({
    cidr = string
    az   = string
  }))
  default = []
}

variable "private_subnets" {
  description = "Private subnet definitions including CIDR block and AZ."
  type = list(object({
    cidr = string
    az   = string
  }))
  default = []
}

variable "nat_gateway_enabled" {
  description = "Create a managed NAT Gateway in the first public subnet."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default     = {}
}
