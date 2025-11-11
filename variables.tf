# -------------------- 기본 메타 설정 --------------------
variable "aws_region" {
  description = "리소스를 배포할 AWS 리전."
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "VPC 리소스 이름/태그에 사용할 접두사."
  type        = string
  default     = "app"
}

# -------------------- VPC 및 서브넷 CIDR --------------------
variable "vpc_cidr" {
  description = "VPC에 할당할 CIDR 블록."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "퍼블릭 서브넷 CIDR/AZ 정의 리스트."
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
  description = "프라이빗 서브넷 CIDR/AZ 정의 리스트."
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
  description = "프라이빗 서브넷용 NAT Gateway 생성 여부."
  type        = bool
  default     = true
}

# -------------------- 공통 태그 --------------------
variable "tags" {
  description = "모든 네트워크 리소스에 공통으로 붙일 태그."
  type        = map(string)
  default     = {}
}

# -------------------- SSH 및 EC2 설정 --------------------
variable "allowed_ssh_cidr" {
  description = "퍼블릭 배스천에 SSH 접속을 허용할 CIDR."
  type        = string
  default     = "221.142.31.34/32"
}

variable "ssh_key_name" {
  description = "AWS에 등록할 키 페어 이름."
  type        = string
  default     = "app-key"
}

variable "ssh_private_key_path" {
  description = "생성된 PEM 키를 저장할 로컬 경로."
  type        = string
  default     = "keys/app-key.pem"
}

variable "public_instance_type" {
  description = "퍼블릭 배스천 인스턴스 타입."
  type        = string
  default     = "t3.micro"
}

variable "private_instance_type" {
  description = "프라이빗 애플리케이션 인스턴스 타입."
  type        = string
  default     = "t3.micro"
}

# -------------------- 환경 변수 버킷 --------------------
variable "env_bucket_name" {
  description = "S3 환경 변수 버킷 이름 (비워두면 자동 생성)."
  type        = string
  default     = ""
}

variable "env_object_key" {
  description = "env 파일을 저장할 S3 객체 키."
  type        = string
  default     = "app.env"
}

variable "env_bucket_allowed_principals" {
  description = "S3 버킷/객체에 접근을 허용할 IAM 주체 ARN 목록 (ECS 역할 등)."
  type        = list(string)
  default     = []
}

# -------------------- ECR 설정 --------------------
variable "ecr_repository_name" {
  description = "컨테이너 이미지를 저장할 ECR 리포지토리 이름."
  type        = string
  default     = "app-service"
}

variable "ecr_image_tag_mutability" {
  description = "ECR 태그 변경 여부(MUTABLE/IMMUTABLE)."
  type        = string
  default     = "MUTABLE"
}

variable "ecr_lifecycle_policy" {
  description = "ECR 라이프사이클 정책(JSON 문자열, 옵션)."
  type        = string
  default     = null
}

# -------------------- ECS/ALB 설정 --------------------
variable "ecs_container_image_tag" {
  description = "배포할 컨테이너 이미지 태그."
  type        = string
  default     = "latest"
}

variable "ecs_container_port" {
  description = "컨테이너 리슨 포트."
  type        = number
  default     = 8080
}

variable "ecs_desired_count" {
  description = "ECS 서비스 desired count."
  type        = number
  default     = 1
}

variable "ecs_task_cpu" {
  description = "태스크 CPU 단위."
  type        = number
  default     = 256
}

variable "ecs_task_memory" {
  description = "태스크 메모리(MB)."
  type        = number
  default     = 512
}

variable "ecs_health_check_path" {
  description = "ALB 헬스체크 경로."
  type        = string
  default     = "/"
}

variable "alb_ingress_cidrs" {
  description = "ALB에 접근할 수 있는 CIDR 목록."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ecs_log_retention_days" {
  description = "CloudWatch 로그 보존일."
  type        = number
  default     = 30
}

variable "ecs_environment_variables" {
  description = "추가 컨테이너 환경 변수."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# -------------------- RDS(MySQL) 설정 --------------------
variable "db_instance_class" {
  description = "RDS 인스턴스 클래스."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "RDS 스토리지 용량(GB)."
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "MySQL 엔진 버전."
  type        = string
  default     = null
}

variable "db_name" {
  description = "생성할 기본 DB 이름."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "RDS 마스터 사용자 이름."
  type        = string
  default     = "appadmin"
}

variable "db_password" {
  description = "RDS 마스터 비밀번호."
  type        = string
  sensitive   = true
}

variable "db_multi_az" {
  description = "RDS Multi-AZ 배포 여부."
  type        = bool
  default     = false
}

variable "db_backup_retention" {
  description = "자동 백업 유지 일수."
  type        = number
  default     = 7
}

variable "db_skip_final_snapshot" {
  description = "삭제 시 최종 스냅샷 생략 여부."
  type        = bool
  default     = true
}
