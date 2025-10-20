# S3 bucket for shared storage
resource "aws_s3_bucket" "wordpress_storage" {
  bucket_prefix = "${var.project_name}-storage-"

  tags = merge(var.tags, {
    Name = "${var.project_name}-storage-bucket"
  })
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "wordpress_storage" {
  bucket = aws_s3_bucket.wordpress_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "wordpress_storage" {
  bucket = aws_s3_bucket.wordpress_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "wordpress_storage" {
  bucket = aws_s3_bucket.wordpress_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}