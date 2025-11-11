# -------------------- 필수 입력 --------------------
variable "name" {
  description = "인스턴스 이름/태그."
  type        = string
}

variable "ami_id" {
  description = "배포할 AMI ID."
  type        = string
}

variable "instance_type" {
  description = "인스턴스 타입."
  type        = string
}

variable "subnet_id" {
  description = "인스턴스가 속할 서브넷 ID."
  type        = string
}

variable "security_group_ids" {
  description = "할당할 보안 그룹 ID 목록."
  type        = list(string)
}

variable "associate_public_ip" {
  description = "퍼블릭 IP 자동 할당 여부."
  type        = bool
  default     = false
}

variable "key_name" {
  description = "인스턴스에 적용할 키 페어 이름."
  type        = string
}

variable "tags" {
  description = "인스턴스에 적용할 공통 태그."
  type        = map(string)
  default     = {}
}

variable "user_data" {
  description = "인스턴스 부팅 시 실행할 user_data 스크립트."
  type        = string
  default     = null
}
