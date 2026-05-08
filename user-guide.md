# Lab 1.3 User Guide - S3 Data Lake Foundation

My experience building a production-grade S3 data lake from scratch using Terraform.

---

## Why this lab matters

After IAM and VPC, this lab is where data actually starts to live. A VPC is your private network; an S3 data lake is your organisation's long-term memory. Every ETL pipeline, every Glue job, every Redshift COPY command - they all read from and write to S3. Getting the bucket configuration right from day one avoids the kind of compliance failures that cost companies tens of millions in GDPR fines.

The lab uses the Netflix data flow as a reference: raw data lands in an immutable zone, Spark jobs clean it into a processed zone, analysts pull from a curated zone, and temporary job outputs are cleaned up automatically. Building this structure in Terraform makes it reproducible across environments and auditable by default.

---

## What I built

Two S3 buckets, not one. AWS requires the access log destination to be a **different** bucket from the one you are logging. That detail is easy to miss if you have only done this in the console - the console silently validates it. Terraform applies whatever you write, so if you point logging at the same bucket, the apply succeeds but AWS silently discards the logs.

**data-lake-prod-{account_id}** - the main bucket. Named with the account ID to guarantee global uniqueness without guessing. Configured with:

- SSE-S3 encryption (AES256) applied by default on every object
- Bucket policy that denies any upload without an explicit `x-amz-server-side-encryption: AES256` header
- Versioning enabled so accidental deletes are recoverable
- Server access logging pointing at the companion log bucket
- Public access blocked on all four controls
- Lifecycle rules for cost management

**data-lake-prod-{account_id}-access-logs** - the log destination. Separate encryption, separate public access block, and a bucket policy that explicitly grants S3's log delivery service permission to write. Without that policy, the logs are never written and you get no error - they just silently stop.

**Zone markers** - five zero-byte objects (`raw/`, `processed/`, `curated/`, `temp/`, `archive/`) that create visible "folders" in the S3 console. S3 has no real directory concept - these are just objects with a trailing slash. They serve as both documentation and anchors for lifecycle rules.

---

## Issues I ran into

### The logging bucket needs an explicit delivery policy

When I first set up server access logging in the console, it just worked. In Terraform, the apply succeeded but no logs appeared. The reason: starting in 2022, AWS requires the log destination bucket to have a bucket policy that explicitly allows the `logging.s3.amazonaws.com` service principal to write to it. The older ACL-based approach no longer works by default on buckets created with `ObjectOwnership = BucketOwnerEnforced`.

The fix is an `aws_s3_bucket_policy` on the logging bucket that grants `s3:PutObject` to `logging.s3.amazonaws.com` on the `logs/` prefix. Miss this and the logs are silently dropped.

### Lifecycle rules interact in unexpected ways

I initially wrote a single lifecycle rule with transition to Deep Archive after 90 days and expiration for temp objects on day 1. The problem is AWS evaluates all matching rules for an object. A `temp/` object would match the archive transition rule (because it had no prefix filter) before the expiry rule ran on day 1.

The fix is separate, non-overlapping rules with explicit prefix filters - one rule for `temp/` (expiry only), one rule per zone for the archive transition, each scoped to its own prefix. Never use a single blanket rule if you have mixed retention requirements.

### Bucket names must be globally unique across all AWS accounts

The bucket name `data-lake-prod-559050223770` is unique because the account ID is embedded. If you try to create a bucket with a name already taken by anyone in AWS, the apply fails with `BucketAlreadyExists`. Using `data.aws_caller_identity.current.account_id` in the name avoids this entirely.

### Bucket already existed from console work

Like the IAM lab, I had done this lab manually in the console first. When Terraform tried to create the bucket it hit:

```
Error: creating S3 Bucket: BucketAlreadyOwnedByYou
```

The fix is to import:

```bash
terraform import module.data_lake_bucket.aws_s3_bucket.main data-lake-prod-559050223770
terraform import module.logging_bucket.aws_s3_bucket.main data-lake-prod-559050223770-access-logs
```

After importing, Terraform reconciles the existing configuration with the desired state and only applies the differences.

---

## Key takeaways

**Two buckets are required for logging.** AWS will not let you log a bucket's access to itself. Always create a dedicated log destination bucket before referencing it in the logging configuration.

**Lifecycle rules need explicit prefix filters.** A rule without a prefix filter matches every object in the bucket. If you have a 1-day expiry rule and a 90-day archive rule with no filters, every object matches both. Always scope each rule to its intended prefix.

**The logging bucket policy must grant the S3 service principal.** Without it, logs are silently discarded. No error, no warning. Check `get-bucket-policy` on the log bucket if you are not seeing logs.

**SSE-S3 encryption is not the same as enforcing encryption.** Enabling SSE-S3 sets a default - but a caller can still override it. The bucket policy `Deny` on `PutObject` when `x-amz-server-side-encryption` is not `AES256` is what actually enforces it. You need both.

**Versioning cannot be disabled once enabled, only suspended.** If you apply versioning and then try to remove the `aws_s3_bucket_versioning` resource, Terraform destroys the resource but the bucket retains versioning in a `Suspended` state. Plan ahead.

**Terraform destroy on a versioned bucket requires manual cleanup.** If you have uploaded objects (even the zone marker zero-byte files), Terraform cannot destroy the bucket without deleting all versions first. Either use `force_destroy = true` on the bucket or empty it manually before running destroy.

---

## Running it yourself

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform plan
terraform apply
```

Verify with the AWS CLI:

```bash
# Versioning
aws s3api get-bucket-versioning --bucket data-lake-prod-559050223770

# Logging
aws s3api get-bucket-logging --bucket data-lake-prod-559050223770

# Lifecycle rules
aws s3api get-bucket-lifecycle-configuration --bucket data-lake-prod-559050223770

# Public access block
aws s3api get-public-access-block --bucket data-lake-prod-559050223770

# Encryption
aws s3api get-bucket-encryption --bucket data-lake-prod-559050223770

# Bucket policy
aws s3api get-bucket-policy --bucket data-lake-prod-559050223770 --query Policy --output text | python -m json.tool
```

Clean up when done:

```bash
# Empty the bucket first (force_destroy handles this but good practice to know)
aws s3 rm s3://data-lake-prod-559050223770 --recursive
aws s3 rm s3://data-lake-prod-559050223770-access-logs --recursive

terraform destroy
```
