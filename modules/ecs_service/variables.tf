# -------------------- 기본 설정 --------------------
variable "name" {
  description = "ECS 클러스터/서비스 이름 접두사."
  type        = string
}

variable "vpc_id" {
  description = "서비스가 속할 VPC ID."
  type        = string
}

variable "public_subnet_ids" {
  description = "ALB를 배치할 퍼블릭 서브넷 목록."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Fargate 태스크를 배치할 프라이빗 서브넷 목록."
  type        = list(string)
}

variable "repository_url" {
  description = "컨테이너 이미지가 존재하는 ECR 리포지토리 URL."
  type        = string
}

variable "aws_region" {
  description = "배포 리전 (로그 구성을 위해 필요)."
  type        = string
}

variable "image_tag" {
  description = "배포할 이미지 태그."
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "컨테이너가 리슨하는 포트."
  type        = number
  default     = 8080
}

variable "desired_count" {
  description = "ECS 서비스 desired count."
  type        = number
  default     = 1
}

variable "task_cpu" {
  description = "태스크 CPU (예: 256)."
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "태스크 메모리 (MB)."
  type        = number
  default     = 512
}

variable "health_check_path" {
  description = "ALB 타겟 그룹 헬스체크 경로."
  type        = string
  default     = "/"
}

variable "alb_ingress_cidrs" {
  description = "ALB에 접근 가능한 CIDR 목록."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "log_retention_days" {
  description = "CloudWatch 로그 보존일."
  type        = number
  default     = 30
}

variable "env_bucket_arn" {
  description = "env 파일이 저장된 S3 버킷 ARN."
  type        = string
}

variable "env_bucket_name" {
  description = "env 파일 버킷 이름."
  type        = string
}

variable "env_object_key" {
  description = "env 파일 S3 키."
  type        = string
}

variable "environment" {
  description = "추가 컨테이너 환경 변수."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "tags" {
  description = "공통 태그."
  type        = map(string)
  default     = {}
}
