variable "aws_region" {
  description = "AWS region to deploy resources into."
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Prefix used for tagging and naming VPC resources."
  type        = string
  default     = "app"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnet definitions with CIDR blocks and AZs."
  type = list(object({
    cidr = string
    az   = string
  }))
  default = [
    {
      cidr = "10.0.1.0/24"
      az   = "ap-northeast-2a"
    },
    {
      cidr = "10.0.2.0/24"
      az   = "ap-northeast-2c"
    }
  ]
}

variable "private_subnets" {
  description = "List of private subnet definitions with CIDR blocks and AZs."
  type = list(object({
    cidr = string
    az   = string
  }))
  default = [
    {
      cidr = "10.0.11.0/24"
      az   = "ap-northeast-2a"
    },
    {
      cidr = "10.0.12.0/24"
      az   = "ap-northeast-2c"
    }
  ]
}

variable "nat_gateway_enabled" {
  description = "Controls whether a managed NAT Gateway is created for private subnets."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags applied to all network resources."
  type        = map(string)
  default     = {}
}
