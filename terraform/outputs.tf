output "account_id" {
  description = "AWS account the resources were deployed into"
  value       = data.aws_caller_identity.current.account_id
}

output "data_lake_bucket_id" {
  description = "Name of the main data lake bucket"
  value       = module.data_lake_bucket.bucket_id
}

output "data_lake_bucket_arn" {
  description = "ARN of the main data lake bucket"
  value       = module.data_lake_bucket.bucket_arn
}

output "data_lake_bucket_domain_name" {
  description = "Regional domain name of the main data lake bucket"
  value       = module.data_lake_bucket.bucket_domain_name
}

output "logging_bucket_id" {
  description = "Name of the access-log destination bucket"
  value       = module.logging_bucket.bucket_id
}

output "logging_bucket_arn" {
  description = "ARN of the access-log destination bucket"
  value       = module.logging_bucket.bucket_arn
}
