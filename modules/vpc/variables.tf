# -------------------- 네이밍/기본 정보 --------------------
variable "name" {
  description = "리소스 이름을 구성할 접두사."
  type        = string
}

# -------------------- CIDR 정의 --------------------
variable "vpc_cidr" {
  description = "VPC에 부여할 CIDR 블록."
  type        = string
}

variable "public_subnets" {
  description = "퍼블릭 서브넷 CIDR/AZ 정의 리스트."
  type = list(object({
    cidr = string
    az   = string
  }))
  default = []
}

variable "private_subnets" {
  description = "프라이빗 서브넷 CIDR/AZ 정의 리스트."
  type = list(object({
    cidr = string
    az   = string
  }))
  default = []
}

# -------------------- 부가 리소스 --------------------
variable "nat_gateway_enabled" {
  description = "첫 번째 퍼블릭 서브넷에 NAT Gateway 생성 여부."
  type        = bool
  default     = true
}

# -------------------- 공통 태그 --------------------
variable "tags" {
  description = "생성되는 모든 리소스에 적용할 태그."
  type        = map(string)
  default     = {}
}
