locals {
  common_tags = {
    Project     = var.project
    Lab         = var.lab
    ManagedBy   = "terraform"
    Environment = var.environment
    Owner       = var.owner
    Purpose     = var.purpose
    CostCenter  = var.cost_center
  }
}

resource "aws_s3_bucket" "main" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = merge(local.common_tags, { Name = var.bucket_name })
}

# Block all public access on the log bucket
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encrypt the log bucket itself with SSE-S3
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = false
  }
}

# Enforce bucket owner ownership so ACL-based delivery still works
resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Grant S3 log delivery service permission to write access logs.
# Required since AWS stopped honouring ACL-based log delivery for new buckets.
resource "aws_s3_bucket_policy" "log_delivery" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ServerAccessLogsPolicy"
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.main.arn}/logs/*"
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:s3:::*"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.main]
}
