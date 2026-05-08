output "bucket_id" {
  description = "Name of the log destination bucket"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "ARN of the log destination bucket"
  value       = aws_s3_bucket.main.arn
}
