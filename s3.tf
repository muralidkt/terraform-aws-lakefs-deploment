resource "aws_s3_bucket" "lakefs" {
  bucket = "abc-lakefs-bucket-${var.environment}"
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "lakefs" {
  bucket = aws_s3_bucket.lakefs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lakefs" {
  bucket = aws_s3_bucket.lakefs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "lakefs" {
  bucket = aws_s3_bucket.lakefs.id
  policy = jsonencode({
    Id      = "lakeFSPolicy"
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "lakeFSObjects"
        Effect = "Allow"
        Principal = {
          AWS = [aws_iam_role.lakefs_role.arn]
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = ["${aws_s3_bucket.lakefs.arn}/*"]
      },
      {
        Sid    = "lakeFSBucket"
        Effect = "Allow"
        Principal = {
          AWS = [aws_iam_role.lakefs_role.arn]
        }
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = [aws_s3_bucket.lakefs.arn]
      }
    ]
  })
}

# Block public access
resource "aws_s3_bucket_public_access_block" "lakefs" {
  bucket = aws_s3_bucket.lakefs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "lakefs" {
  count  = var.s3_lifecycle_rules_enabled ? 1 : 0
  bucket = aws_s3_bucket.lakefs.id

  rule {
    id     = "cleanup_noncurrent_versions"
    status = "Enabled"

    filter {
      prefix = ""  # Apply to all objects
    }

    noncurrent_version_expiration {
      noncurrent_days = var.s3_noncurrent_version_expiration_days
    }
  }
} 