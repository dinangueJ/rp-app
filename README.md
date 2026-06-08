# AWS Resume Portal – Infrastructure as Code (Terraform)

## Live Demo
https://resume.dinangue.com

---

## Project Overview

This project is a fully automated AWS cloud infrastructure built using Terraform.  
It deploys a scalable, secure, and production-style web application accessible via a custom domain.

The architecture follows AWS best practices for high availability, security, and scalability.

---

## Architecture

User → Route 53 → CloudFront → ALB → Auto Scaling Group → EC2 → Application → RDS → S3

---

## Technologies Used

- Terraform (Infrastructure as Code)
- AWS CloudFront (CDN)
- AWS Route 53 (DNS)
- AWS Certificate Manager (SSL/TLS)
- Application Load Balancer (ALB)
- Auto Scaling Group (ASG)
- EC2 (Compute)
- RDS (Database)
- S3 (Storage)
- AWS KMS (Encryption)
- AWS WAF (Security)

---

## Security Features

- HTTPS encryption using ACM certificates
- AWS WAF protection against:
  - SQL injection
  - Bad inputs
  - Bot traffic
  - IP reputation threats
- KMS encryption for RDS and S3
- Private subnets for backend resources
- Security groups with least privilege access

---

## Scalability Features

- Auto Scaling Group (min 2, max 4 instances)
- CPU-based scaling policies
- Load balancing via ALB
- CloudFront caching for global performance

---

## High Availability

- Multi-AZ deployment (us-east-1a / us-east-1b)
- Health checks via ALB
- Automatic instance replacement (self-healing)
- Distributed architecture across subnets

---

## Infrastructure as Code

All infrastructure is fully provisioned using Terraform:

- VPC and Subnets
- Security Groups
- ALB and Target Groups
- Launch Templates
- Auto Scaling Group
- CloudFront Distribution
- WAF Web ACL
- KMS Keys
- IAM Roles

---

## Deployment Flow

1. Terraform provisions AWS infrastructure
2. EC2 instances launch using Auto Scaling Group
3. User data script installs dependencies and application
4. Application is pulled from GitHub
5. ALB routes traffic to healthy instances
6. CloudFront distributes content globally
7. Route 53 maps custom domain to CloudFront

---

## Validation

- Application accessible via CloudFront
- Custom domain working successfully
- Auto Scaling tested and functional
- Instance health checks active
- WAF rules actively protecting traffic

---

## Repository Structure

- vpc.tf
- alb.tf
- asg.tf
- cloudfront.tf
- waf.tf
- kms.tf
- rds.tf
- s3.tf
- iam.tf
- outputs.tf
- variables.tf
- README.md

---

## Future Improvements

- CI/CD pipeline using GitHub Actions
- Blue/green deployments
- Docker containerization
- Monitoring with CloudWatch dashboards
- Multi-region disaster recovery

---

## Author

Jeanne Dinangue  
Cloud & DevOps Engineer

---

## Summary

This project demonstrates a production-ready AWS infrastructure built using Terraform with focus on scalability, security, automation, and real-world DevOps practices.