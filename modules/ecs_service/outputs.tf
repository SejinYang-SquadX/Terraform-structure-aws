output "cluster_name" {
  description = "ECS 클러스터 이름."
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "ECS 서비스 이름."
  value       = aws_ecs_service.this.name
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS."
  value       = aws_lb.this.dns_name
}

output "task_role_arn" {
  description = "ECS 태스크 IAM 역할 ARN."
  value       = aws_iam_role.task.arn
}

output "alb_security_group_id" {
  description = "ALB 보안 그룹 ID."
  value       = aws_security_group.alb.id
}

output "service_security_group_id" {
  description = "ECS 서비스 보안 그룹 ID."
  value       = aws_security_group.service.id
}
