# ─── ACM CERTIFICATE ──────────────────────────────────────────────────────────
resource "aws_acm_certificate" "main" {
  domain_name               = "dinangue.com"
  subject_alternative_names = ["*.dinangue.com"]
  validation_method         = "DNS"


  tags = { Project = "ResumePortal" }


  lifecycle {
    create_before_destroy = true
  }
}


# ─── ROUTE 53 HOSTED ZONE ─────────────────────────────────────────────────────
data "aws_route53_zone" "main" {
  name         = "dinangue.com"
  private_zone = false
}


# ─── DNS VALIDATION RECORDS ───────────────────────────────────────────────────
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  allow_overwrite = true
  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}


# ─── CERTIFICATE VALIDATION ───────────────────────────────────────────────────
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}


