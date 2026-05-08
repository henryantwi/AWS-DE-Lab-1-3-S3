output "bucket_id" {
  description = "Name of the data lake bucket"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "ARN of the data lake bucket"
  value       = aws_s3_bucket.main.arn
}

output "bucket_domain_name" {
  description = "Regional domain name of the data lake bucket"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}
