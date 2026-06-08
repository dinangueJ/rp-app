# ─────────────────────────────────────────────
# S3 Bucket 1: Frontend (no encryption)
# ─────────────────────────────────────────────
resource "aws_s3_bucket" "rp_frontend" {
  bucket = "rp-frontend-jed"
  force_destroy = true


  tags = {
    Project = "ResumePortal"
  }
}


resource "aws_s3_bucket_public_access_block" "rp_frontend_pab" {
  bucket = aws_s3_bucket.rp_frontend.id


  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_versioning" "rp_frontend_versioning" {
  bucket = aws_s3_bucket.rp_frontend.id


  versioning_configuration {
    status = "Disabled"
  }
}


resource "aws_s3_object" "rp_index_html" {
  bucket       = aws_s3_bucket.rp_frontend.id
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html"


  tags = {
    Project = "ResumePortal"
  }
}


# ─────────────────────────────────────────────
# S3 Bucket 2: Resumes (SSE-KMS, versioning on)
# ─────────────────────────────────────────────
resource "aws_s3_bucket" "rp_resumes" {
  bucket = "rp-resumes-jed"
  force_destroy = true


  tags = {
    Project = "ResumePortal"
  }
}


resource "aws_s3_bucket_public_access_block" "rp_resumes_pab" {
  bucket = aws_s3_bucket.rp_resumes.id


  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_versioning" "rp_resumes_versioning" {
  bucket = aws_s3_bucket.rp_resumes.id


  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "rp_resumes_encryption" {
  bucket = aws_s3_bucket.rp_resumes.id


  rule {
    bucket_key_enabled = true


    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.rp_s3_key.arn
    }
  }
}
