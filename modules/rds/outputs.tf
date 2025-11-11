# -------------------- RDS 출력 --------------------
output "endpoint" {
  description = "RDS 엔드포인트 주소."
  value       = aws_db_instance.this.endpoint
}

output "port" {
  description = "DB 포트."
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "DB 이름."
  value       = aws_db_instance.this.db_name
}

output "address" {
  description = "포트 제외한 DB 엔드포인트 호스트."
  value       = aws_db_instance.this.address
}

output "security_group_id" {
  description = "DB 보안 그룹 ID."
  value       = aws_security_group.db.id
}

output "db_instance_id" {
  description = "DB 인스턴스 ID."
  value       = aws_db_instance.this.id
}
