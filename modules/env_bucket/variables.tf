# -------------------- 입력 변수 --------------------
variable "bucket_name" {
  description = "생성할 S3 버킷 이름."
  type        = string
}

variable "object_key" {
  description = "env 파일을 저장할 객체 키."
  type        = string
}

variable "env_content" {
  description = "S3에 업로드할 env 파일 내용."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "버킷 및 객체에 적용할 태그."
  type        = map(string)
  default     = {}
}
