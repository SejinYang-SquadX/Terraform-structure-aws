# -------------------- ECR 리포지토리 --------------------
resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  force_delete = true

  tags = merge(var.tags, {
    Name = var.name
  })
}

# -------------------- 라이프사이클 정책 (선택) --------------------
resource "aws_ecr_lifecycle_policy" "this" {
  count      = var.lifecycle_policy_json == null ? 0 : 1
  repository = aws_ecr_repository.this.name
  policy     = var.lifecycle_policy_json
}
