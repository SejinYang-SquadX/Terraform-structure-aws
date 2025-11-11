# -------------------- 인스턴스 출력 --------------------
output "instance_id" {
  description = "생성된 인스턴스 ID."
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "퍼블릭 IP (없으면 null)."
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "프라이빗 IP."
  value       = aws_instance.this.private_ip
}
