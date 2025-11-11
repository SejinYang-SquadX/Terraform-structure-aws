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
