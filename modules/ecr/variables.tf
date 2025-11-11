# -------------------- 입력 변수 --------------------
variable "name" {
  description = "ECR 리포지토리 이름."
  type        = string
}

variable "tags" {
  description = "리포지토리에 적용할 공통 태그."
  type        = map(string)
  default     = {}
}

variable "image_tag_mutability" {
  description = "태그 변경 허용 여부 (MUTABLE/IMMUTABLE)."
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "푸시 시 이미지 스캔 여부."
  type        = bool
  default     = true
}

variable "lifecycle_policy_json" {
  description = "선택적 라이프사이클 정책(JSON 문자열)."
  type        = string
  default     = null
}
