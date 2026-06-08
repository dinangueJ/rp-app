# ─────────────────────────────────────────────
# SES Email Identity
# ─────────────────────────────────────────────
resource "aws_sesv2_email_identity" "rp_ses_identity" {
  email_identity = "jeannedinangue@gmail.com"


  tags = {
    Project = "ResumePortal"
  }
}
