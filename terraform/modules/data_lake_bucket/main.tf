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

# ── Main data lake bucket ─────────────────────────────────────────────────────
resource "aws_s3_bucket" "main" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = merge(local.common_tags, { Name = var.bucket_name })
}

# ── Block all public access ────────────────────────────────────────────────────
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── SSE-S3 encryption (AES256) ────────────────────────────────────────────────
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = false
  }
}

# ── Versioning ────────────────────────────────────────────────────────────────
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ── Server access logging - points to the companion log bucket ────────────────
resource "aws_s3_bucket_logging" "main" {
  bucket        = aws_s3_bucket.main.id
  target_bucket = var.logging_bucket_id
  target_prefix = "logs/"
}

# ── Lifecycle rules ───────────────────────────────────────────────────────────
# Rule 1: delete temp/ objects after 1 day
# Rule 2-5: transition each data zone prefix to Deep Archive after 90 days
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "temp-expiry"
    status = "Enabled"

    filter {
      prefix = "temp/"
    }

    expiration {
      days = 1
    }
  }

  rule {
    id     = "raw-archive"
    status = "Enabled"

    filter {
      prefix = "raw/"
    }

    transition {
      days          = 90
      storage_class = "DEEP_ARCHIVE"
    }
  }

  rule {
    id     = "processed-archive"
    status = "Enabled"

    filter {
      prefix = "processed/"
    }

    transition {
      days          = 90
      storage_class = "DEEP_ARCHIVE"
    }
  }

  rule {
    id     = "curated-archive"
    status = "Enabled"

    filter {
      prefix = "curated/"
    }

    transition {
      days          = 90
      storage_class = "DEEP_ARCHIVE"
    }
  }

  rule {
    id     = "archive-deep"
    status = "Enabled"

    filter {
      prefix = "archive/"
    }

    transition {
      days          = 90
      storage_class = "DEEP_ARCHIVE"
    }
  }

  depends_on = [aws_s3_bucket_versioning.main]
}

# ── Bucket policy: deny unencrypted uploads ───────────────────────────────────
# Any PutObject request that does not carry SSE-S3 (AES256) is rejected.
# The public access block must be applied first to avoid policy conflicts.
resource "aws_s3_bucket_policy" "deny_unencrypted" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyUnencryptedUploads"
        Effect = "Deny"
        Principal = {
          AWS = "*"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.main.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.main]
}
