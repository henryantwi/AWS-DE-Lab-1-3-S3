output "zone_keys" {
  description = "S3 object keys for the created zone prefix markers"
  value       = [for obj in aws_s3_object.zone : obj.key]
}
