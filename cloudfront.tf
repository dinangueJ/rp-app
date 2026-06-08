# ─────────────────────────────────────────────
# CloudFront Origin Access Control (OAC)
# ─────────────────────────────────────────────
resource "aws_cloudfront_origin_access_control" "rp_frontend_oac" {
  name                              = "rp-frontend-oac"
  description                       = "OAC for resume portal frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


# ─────────────────────────────────────────────
# CloudFront Distribution
# ─────────────────────────────────────────────
resource "aws_cloudfront_distribution" "rp_frontend" {
  enabled             = true
  comment             = "Frontend distribution for resume portal"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  http_version        = "http2and3"
  is_ipv6_enabled     = true


  aliases = ["resume.dinangue.com"]


  # ── Origin — S3 frontend bucket ──
  origin {
    domain_name              = aws_s3_bucket.rp_frontend.bucket_regional_domain_name
    origin_id                = "rp-frontend-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.rp_frontend_oac.id
  }


  # ── Default Cache Behavior ──
  default_cache_behavior {
    target_origin_id       = "rp-frontend-s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true


    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized (AWS managed)


    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
  }


  # ── Geo restriction — none ──
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }


  # ── SSL Certificate ──
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.main.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }


  tags = {
    Name    = "rp-frontend"
    Project = "ResumePortal"
  }
}


# ─────────────────────────────────────────────
# S3 Bucket Policy — allow CloudFront OAC only
# ─────────────────────────────────────────────
resource "aws_s3_bucket_policy" "rp_frontend_policy" {
  bucket = aws_s3_bucket.rp_frontend.id


  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAC"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.rp_frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.rp_frontend.arn
          }
        }
      }
    ]
  })
}


# ─────────────────────────────────────────────
# Route 53 — resume.dinangue.com → CloudFront
# ─────────────────────────────────────────────
resource "aws_route53_record" "rp_resume_record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "resume.dinangue.com"
  type    = "A"


  alias {
    name                   = aws_cloudfront_distribution.rp_frontend.domain_name
    zone_id                = aws_cloudfront_distribution.rp_frontend.hosted_zone_id
    evaluate_target_health = false
  }


  allow_overwrite = true
}



