# ─────────────────────────────────────────────
# EC2 Instance 1 — us-east-1a
# ─────────────────────────────────────────────
resource "aws_instance" "rp_server_1" {
  ami                    = "ami-00e801948462f718a"  # Amazon Linux 2023 us-east-1
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.rp_private_1a.id
  vpc_security_group_ids = [aws_security_group.rp_ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.rp_ec2_profile.name
  associate_public_ip_address = false


  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }


  user_data = templatefile("${path.module}/user-data.sh", {
    resume_bucket  = aws_s3_bucket.rp_resumes.id
    db_secret_name = aws_secretsmanager_secret.rp_db_credentials.name
    sender_email   = aws_sesv2_email_identity.rp_ses_identity.email_identity
     aws_region = "us-east-1"
  })


  tags = {
    Name    = "rp-server-1"
    Project = "ResumePortal"
  }
}


# ─────────────────────────────────────────────
# EC2 Instance 2 — us-east-1b
# ─────────────────────────────────────────────
resource "aws_instance" "rp_server_2" {
  ami                    = "ami-00e801948462f718a"  # Amazon Linux 2023 us-east-1
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.rp_private_1b.id
  vpc_security_group_ids = [aws_security_group.rp_ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.rp_ec2_profile.name
  associate_public_ip_address = false


  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }


  user_data = templatefile("${path.module}/user-data.sh", {
    resume_bucket  = aws_s3_bucket.rp_resumes.id
    db_secret_name = aws_secretsmanager_secret.rp_db_credentials.name
    sender_email   = aws_sesv2_email_identity.rp_ses_identity.email_identity
    aws_region = "us-east-1"
  })


  tags = {
    Name    = "rp-server-2"
    Project = "ResumePortal"
  }
}
