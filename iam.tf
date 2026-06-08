# ─────────────────────────────────────────────
# IAM Role — EC2 trusted entity
# ─────────────────────────────────────────────
resource "aws_iam_role" "rp_ec2_role" {
  name        = "rp-ec2-role"
  description = "Allows EC2 to access S3, Secrets Manager, SES, and Session Manager"


  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })


  tags = {
    Project = "ResumePortal"
  }
}


# ─────────────────────────────────────────────
# Managed Policy — SSM Session Manager access
# ─────────────────────────────────────────────
resource "aws_iam_role_policy_attachment" "rp_ec2_ssm" {
  role       = aws_iam_role.rp_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# ─────────────────────────────────────────────
# Inline Policy — least privilege custom perms
# ─────────────────────────────────────────────
resource "aws_iam_role_policy" "rp_ec2_policy" {
  name = "rp-ec2-policy"
  role = aws_iam_role.rp_ec2_role.id


  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3UploadResumes"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::rp-resumes-*/*"
      },
      {
        Sid    = "AllowReadSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:us-east-1:960671880734:secret:rp/*"
      },
      {
        Sid    = "AllowKMSForS3AndRDS"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [
          aws_kms_key.rp_s3_key.arn,
          aws_kms_key.rp_rds_key.arn
        ]
      },
      {
        Sid    = "AllowSendEmail"
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:CreateLogGroup"
        ]
        Resource = "arn:aws:logs:us-east-1:960671880734:log-group:/rp/*"
      }
    ]
  })
}


# ─────────────────────────────────────────────
# Instance Profile — wraps the role for EC2
# ─────────────────────────────────────────────
resource "aws_iam_instance_profile" "rp_ec2_profile" {
  name = "rp-ec2-profile"
  role = aws_iam_role.rp_ec2_role.name


  tags = {
    Project = "ResumePortal"
  }
}


# ─────────────────────────────────────────────
# KMS Key Policy update — add EC2 role as Key User
# on both rp-s3-key and rp-rds-key
# ─────────────────────────────────────────────
resource "aws_kms_grant" "rp_s3_key_ec2_grant" {
  name              = "rp-s3-key-ec2-grant"
  key_id            = aws_kms_key.rp_s3_key.key_id
  grantee_principal = aws_iam_role.rp_ec2_role.arn
  operations        = ["Decrypt", "GenerateDataKey"]
}


resource "aws_kms_grant" "rp_rds_key_ec2_grant" {
  name              = "rp-rds-key-ec2-grant"
  key_id            = aws_kms_key.rp_rds_key.key_id
  grantee_principal = aws_iam_role.rp_ec2_role.arn
  operations        = ["Decrypt", "GenerateDataKey"]
}
