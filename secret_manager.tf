# ─────────────────────────────────────────────
# Secrets Manager Secret — RDS Credentials
# ─────────────────────────────────────────────
resource "aws_secretsmanager_secret" "rp_db_credentials" {
  name        = "rp/db-credentials"
  description = "PostgreSQL credentials for resume portal"


  # Using default aws/secretsmanager key (free)
  # kms_key_id is omitted to use the default AWS managed key
tags = {
    Project = "ResumePortal"
  }
}


# ─────────────────────────────────────────────
# Secret Value — RDS credentials as JSON
# ─────────────────────────────────────────────
resource "aws_secretsmanager_secret_version" "rp_db_credentials_value" {
  secret_id = aws_secretsmanager_secret.rp_db_credentials.id


  secret_string = jsonencode({
    username            = "portaladmin"
    password            = "utrain123!"
    engine              = "postgres"
    host                = aws_db_instance.rp_db.address
    port                = 5432
    dbname              = "postgres"
    dbInstanceIdentifier = aws_db_instance.rp_db.identifier
  })
}




