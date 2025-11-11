# -------------------- 모듈 출력 --------------------
output "vpc_id" {
  description = "생성된 VPC의 ID."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "모든 퍼블릭 서브넷 ID."
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  description = "모든 프라이빗 서브넷 ID."
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "internet_gateway_id" {
  description = "연결된 인터넷 게이트웨이 ID."
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_id" {
  description = "NAT Gateway 생성 시 해당 ID (없으면 null)."
  value       = length(aws_nat_gateway.this) > 0 ? aws_nat_gateway.this[0].id : null
}
