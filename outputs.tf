# -------------------- 네트워크 출력 --------------------
output "vpc_id" {
  description = "네트워크 모듈이 생성한 VPC ID."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "모든 퍼블릭 서브넷 ID 목록."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "모든 프라이빗 서브넷 ID 목록."
  value       = module.network.private_subnet_ids
}

# -------------------- EC2 출력 --------------------
output "bastion_instance_id" {
  description = "퍼블릭 배스천 인스턴스 ID."
  value       = module.bastion_instance.instance_id
}

output "bastion_public_ip" {
  description = "배스천 인스턴스 퍼블릭 IP."
  value       = module.bastion_instance.public_ip
}

output "private_instance_id" {
  description = "프라이빗 인스턴스 ID."
  value       = module.private_instance.instance_id
}

output "private_instance_private_ip" {
  description = "프라이빗 인스턴스의 프라이빗 IP."
  value       = module.private_instance.private_ip
}

output "ssh_private_key_path" {
  description = "생성된 PEM 키 파일 경로."
  value       = local_sensitive_file.private_key_pem.filename
  sensitive   = true
}

# -------------------- RDS 출력 --------------------
output "database_endpoint" {
  description = "RDS MySQL 엔드포인트."
  value       = module.database.endpoint
}

output "database_port" {
  description = "RDS MySQL 포트."
  value       = module.database.port
}

output "database_name" {
  description = "생성된 데이터베이스명."
  value       = module.database.database_name
}

output "database_address" {
  description = "포트 제외 RDS 호스트."
  value       = module.database.address
}

# -------------------- 환경 변수 S3 --------------------
output "env_bucket_name" {
  description = "애플리케이션 .env 파일을 저장한 버킷 이름."
  value       = module.env_bucket.bucket_name
}

output "env_object_key" {
  description = "env 파일이 업로드된 키."
  value       = module.env_bucket.object_key
}

# -------------------- ECR --------------------
output "ecr_repository_url" {
  description = "컨테이너 이미지를 push/pull할 ECR URL."
  value       = module.container_registry.repository_url
}

output "ecr_repository_name" {
  description = "ECR 리포지토리 이름."
  value       = module.container_registry.repository_name
}

output "alb_dns_name" {
  description = "외부에서 접근할 ALB DNS."
  value       = module.ecs_service.alb_dns_name
}

output "ecs_cluster_name" {
  description = "ECS 클러스터 이름."
  value       = module.ecs_service.cluster_name
}

output "ecs_service_name" {
  description = "ECS 서비스 이름."
  value       = module.ecs_service.service_name
}
