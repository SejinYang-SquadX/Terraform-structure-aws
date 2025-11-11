# -------------------- 필수 설정 --------------------
variable "identifier" {
  description = "RDS 인스턴스 식별자."
  type        = string
}

variable "database_name" {
  description = "초기 생성 DB 이름."
  type        = string
}

variable "master_username" {
  description = "마스터 계정 사용자."
  type        = string
}

variable "master_password" {
  description = "마스터 계정 비밀번호."
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "DB 인스턴스 클래스."
  type        = string
}

variable "allocated_storage" {
  description = "스토리지 용량(GB)."
  type        = number
}

variable "engine_version" {
  description = "MySQL 엔진 버전(지정하지 않으면 최신)."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "DB Subnet Group에 포함될 서브넷 ID."
  type        = list(string)
}

variable "vpc_id" {
  description = "보안 그룹 생성을 위한 VPC ID."
  type        = string
}

variable "allowed_security_group_ids" {
  description = "DB에 접근을 허용할 보안 그룹 ID 목록."
  type        = list(string)
}

variable "multi_az" {
  description = "Multi-AZ 배포 여부."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "자동 백업 유지 일수."
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "삭제 시 최종 스냅샷 생략 여부."
  type        = bool
  default     = true
}

variable "tags" {
  description = "공통 태그."
  type        = map(string)
  default     = {}
}
