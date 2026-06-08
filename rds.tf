# ─────────────────────────────────────────────
# DB Subnet Group
# ─────────────────────────────────────────────
resource "aws_db_subnet_group" "rp_db_subnet_group" {
  name        = "rp-db-subnet-group"
  description = "Private subnets for resume portal RDS"
  subnet_ids  = [
    aws_subnet.rp_private_1a.id,
    aws_subnet.rp_private_1b.id
  ]


  tags = {
    Project = "ResumePortal"
  }
}


# ─────────────────────────────────────────────
# RDS PostgreSQL Instance
# ─────────────────────────────────────────────
resource "aws_db_instance" "rp_db" {
  identifier        = "rp-db"
  engine            = "postgres"
  engine_version    = "17"
  instance_class    = "db.t3.micro"


  # Storage
  storage_type          = "gp3"
  allocated_storage     = 20
  max_allocated_storage = 0  # disables autoscaling


  # Credentials
  db_name  = "postgres"
  username = "portaladmin"
  password = "utrain123!"  # move to Secrets Manager next step


  # Networking
  db_subnet_group_name   = aws_db_subnet_group.rp_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rp_rds_sg.id]
  publicly_accessible    = false
  port                   = 5432


  # Encryption
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rp_rds_key.arn


  # Availability
  availability_zone      = "us-east-1a"
  multi_az               = false


  # Backups
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"


  # Misc
  skip_final_snapshot    = true
  deletion_protection    = false


  tags = {
    Name    = "rp-db"
    Project = "ResumePortal"
  }
}


