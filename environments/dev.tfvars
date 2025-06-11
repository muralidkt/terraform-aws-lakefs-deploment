aws_region         = "eu-central-1"
environment        = "dev"
project_name       = "lakefs"
instance_type      = "t3.medium"
lakefs_version     = "0.112.0"
vpc_id             = "vpc-00000000000000000"
private_subnet_ids = ["subnet-00000000000000000", "subnet-00000000000000000", "subnet-00000000000000000"]
public_subnet_ids  = ["subnet-00000000000000000", "subnet-00000000000000000", "subnet-00000000000000000"]
certificate_arn    = "arn:aws:acm:eu-central-1:000000000000:certificate/00000000-0000-0000-0000-000000000000"
domain_name        = "lakefs-dev.abc.com"
lakefs_bucket      = "abc-lakefs-storage-dev"

tags = {
  Environment = "dev"
  Project     = "lakefs"
  Terraform   = "true"
} 