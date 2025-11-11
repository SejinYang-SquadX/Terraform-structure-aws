output "bucket_name" {
  description = "생성된 S3 버킷 이름."
  value       = aws_s3_bucket.this.id
}

output "object_key" {
  description = "env 파일이 저장된 S3 키."
  value       = aws_s3_object.env_file.key
}

output "bucket_arn" {
  description = "S3 버킷 ARN."
  value       = aws_s3_bucket.this.arn
}
