# Zero-byte prefix objects that create visible "folders" in the S3 console.
# S3 has no directory concept; these are just objects with trailing slashes.
# Each zone is scoped to a lifecycle rule in the data_lake_bucket module.

locals {
  zones = ["raw/", "processed/", "curated/", "temp/", "archive/"]
}

resource "aws_s3_object" "zone" {
  for_each = toset(local.zones)

  bucket  = var.bucket_id
  key     = each.value
  content = ""

  server_side_encryption = "AES256"
}
