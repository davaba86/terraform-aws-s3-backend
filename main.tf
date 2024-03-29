# ##############################################################################
# AWS: S3
# ##############################################################################

resource "aws_s3_bucket" "terraform_statefiles" {
  bucket = var.s3_bucket_name

  # Prevent accidental deletion of this S3 bucket
  lifecycle {
    prevent_destroy = true
  }

  tags = var.aws_tags_base
}

resource "aws_s3_bucket_public_access_block" "terraform_statefiles" {
  bucket = aws_s3_bucket.terraform_statefiles.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_statefiles" {
  bucket = aws_s3_bucket.terraform_statefiles.bucket

  rule {
    # Enable S3 Server Side Encryption (S3-SSE)
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = false
  }
}

resource "aws_s3_bucket_logging" "terraform_statefiles" {
  # If bucket name passed to module none then do nothing
  count = var.s3_logging_bucket != "none" ? 1 : 0

  bucket = aws_s3_bucket.terraform_statefiles.id

  target_bucket = var.s3_logging_bucket
  target_prefix = "s3-backend-logging/"
}

resource "aws_s3_bucket_versioning" "terraform_statefiles" {
  bucket = aws_s3_bucket.terraform_statefiles.id
  versioning_configuration {
    # Keep revision history of our state file
    status = "Enabled"
  }
}

# resource "aws_s3_bucket_lifecycle_configuration" "terraform_statefiles" {
#   bucket = aws_s3_bucket.terraform_statefiles.id

#   rule {
#     id = "Empty after ${var.s3_expiration_days} days, #1"

#     abort_incomplete_multipart_upload {
#       days_after_initiation = var.s3_expiration_days
#     }

#     expiration {
#       days                         = var.s3_expiration_days
#       expired_object_delete_marker = false
#     }

#     filter {}

#     noncurrent_version_expiration {
#       noncurrent_days = var.s3_expiration_days
#     }

#     status = "Enabled"
#   }

#   rule {
#     id = "Empty after ${var.s3_expiration_days} days, #2"

#     expiration {
#       days                         = 0
#       expired_object_delete_marker = true
#     }

#     filter {}

#     status = "Enabled"
#   }
# }

# ##############################################################################
# AWS: DynamoDB
# ##############################################################################

#tfsec:ignore:aws-dynamodb-table-customer-key
resource "aws_dynamodb_table" "terraform_statelocks" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  server_side_encryption {
    enabled = true
  }

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = var.aws_tags_base
}
