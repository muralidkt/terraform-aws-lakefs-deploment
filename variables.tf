variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "lakefs"
}

variable "vpc_id" {
  description = "VPC ID where LakeFS will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for LakeFS EC2 instance"
  type        = list(string)
}

variable "lakefs_bucket" {
  description = "Existing S3 bucket for LakeFS storage"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for LakeFS"
  type        = string
  default     = "t3.medium"
}

variable "lakefs_version" {
  description = "LakeFS version to install"
  type        = string
  default     = "0.112.0"
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for LakeFS metadata"
  type        = string
  default     = null
}

variable "dynamodb_point_in_time_recovery" {
  description = "Enable point in time recovery for DynamoDB table"
  type        = bool
  default     = true
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "s3_force_destroy" {
  description = "Allow terraform to destroy the bucket even if it contains objects"
  type        = bool
  default     = false
}

variable "s3_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "s3_lifecycle_rules_enabled" {
  description = "Enable lifecycle rules for the S3 bucket"
  type        = bool
  default     = true
}

variable "s3_noncurrent_version_expiration_days" {
  description = "Number of days to keep noncurrent versions"
  type        = number
  default     = 90
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ARN of ACM certificate for ALB HTTPS listener"
  type        = string
}

variable "domain_name" {
  description = "Domain name for LakeFS UI"
  type        = string
}

variable "asg_min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "health_check_grace_period" {
  description = "Time after instance comes into service before checking health"
  type        = number
  default     = 300
}

variable "enable_nightly_shutdown" {
  description = "Enable nightly shutdown of instances in non-production environments"
  type        = bool
  default     = false
} 