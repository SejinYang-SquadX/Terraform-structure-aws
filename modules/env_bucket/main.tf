resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = merge(var.tags, {
    Name = var.bucket_name
  })
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "env_file" {
  bucket                 = aws_s3_bucket.this.id
  key                    = var.object_key
  content                = var.env_content
  content_type           = "text/plain"
  server_side_encryption = "AES256"
  tags                   = var.tags

  depends_on = [aws_s3_bucket_public_access_block.this]
}
