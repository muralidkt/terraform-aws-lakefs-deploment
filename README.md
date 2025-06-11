# LakeFS Infrastructure

This directory contains the Terraform configuration for deploying LakeFS infrastructure on AWS. The infrastructure includes an Auto Scaling Group, Application Load Balancer, S3 bucket for storage, and DynamoDB for metadata.

## Prerequisites

### Domain Configuration
- The domain is managed in your DNS provider
- Base domain: `example.com`
- LakeFS subdomain pattern: `lakefs-${environment}.example.com`
  - Example: `lakefs-dev.example.com`

### SSL Certificate
- Certificates are manually created in AWS Certificate Manager for sub-domains
- Region: eu-central-1

**Note**: When setting up a new environment, ensure:
1. The subdomain is properly configured in your DNS provider
2. The subdomain certificate exists in AWS Certificate Manager
3. The certificate ARN is correctly specified in the environment's tfvars file

## Infrastructure Components

### Storage
- **S3 Bucket**: `company-lakefs-bucket-${environment}`
  - Example (dev): `company-lakefs-bucket-dev`
  - Used for storing LakeFS data
  - Versioning enabled
  - Server-side encryption with AES256
  - Public access blocked

### Database
- **DynamoDB Table**: `${project_name}-${environment}-lakefs-metadata`
  - Example (dev): `lakefs-dev-lakefs-metadata`
  - Used for LakeFS metadata storage
  - On-demand capacity mode
  - Binary type keys (PartitionKey, ItemKey)

### Compute
- **Auto Scaling Group**
  - Name: `${project_name}-${environment}-lakefs-asg`
  - Example (dev): `lakefs-dev-lakefs-asg`
  - Instance Type: t3.small (configurable per environment)
  - Scheduled scaling for non-production environments:
    - Weekends: Scales down to 0 on Friday 20:00 UTC, up on Monday 06:00 UTC
    - Optional nightly shutdown available

### Load Balancer
- **Application Load Balancer**
  - DNS: `lakefs-${environment}.example.com`
  - Example (dev): `lakefs-dev.example.com`
  - Port: 8000
  - HTTPS enabled with ACM certificate

### IAM
- **IAM Role**: `${project_name}-${environment}-lakefs-role`
  - Example (dev): `lakefs-dev-lakefs-role`
  - Permissions for S3, DynamoDB, and SSM

## Environment Configuration

Example configuration for dev environment (`environments/dev.tfvars`):
```hcl
aws_region         = "eu-central-1"
environment        = "dev"
project_name       = "lakefs"
instance_type      = "t3.small"
lakefs_version     = "1.54.0"
vpc_id             = "vpc-0123456789abcdef0"
private_subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1", "subnet-0123456789abcdef2"]
domain_name        = "lakefs-dev.example.com"
certificate_arn    = "arn:aws:acm:eu-central-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
```

## Deployment Instructions
Prerequisite - Export the AWS_PROFILE to the account where you want to deploy the setup (eg: export AWS_PROFILE=dev) and login to AWS Account as needed.

1. Initialize Terraform with the appropriate backend:
   ```bash
   terraform init -backend-config=backends/backend_dev.tfvars
   ```

2. Plan the changes:
   ```bash
   terraform plan -var-file="environments/dev.tfvars"
   ```

3. Apply the changes:
   ```bash
   terraform apply -var-file="environments/dev.tfvars"
   ```

4. To destroy the infrastructure:
   ```bash
   terraform destroy -var-file="environments/dev.tfvars"
   ```

## Access and Monitoring

- **LakeFS UI**: https://lakefs-dev.example.com
- **Health Check**: https://lakefs-dev.example.com/health
- **Logs**: Located on EC2 instances at `/var/lib/lakefs/lakefs.log`

### Domain and SSL Verification
1. Verify domain resolution:
   ```bash
   dig lakefs-dev.example.com
   ```
2. Check SSL certificate:
   ```bash
   curl -v https://lakefs-dev.example.com/health
   ```

## Security Notes

1. All data in S3 is encrypted at rest using AES256
2. Public access to S3 bucket is blocked
3. HTTPS is enforced on the ALB
4. IMDSv2 is required on EC2 instances
5. Instance-to-instance communication is restricted by security groups 