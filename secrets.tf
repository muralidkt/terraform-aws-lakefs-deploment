resource "aws_secretsmanager_secret" "lakefs_initial_secrets" {
  name = "${var.project_name}-${var.environment}-lakefs-initial-secrets"
  description = "Stores LakeFS encryption key and admin credentials"
  force_overwrite_replica_secret = true
  recovery_window_in_days = 0  # Disable the recovery window

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-lakefs-initial-secrets"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_secretsmanager_secret_version" "lakefs_initial_secrets" {
  secret_id = aws_secretsmanager_secret.lakefs_initial_secrets.id
  
  secret_string = jsonencode({
    encryption_secret_key = random_password.lakefs_encryption_secret_key.result
    access_key_id         = "AKIA${random_password.lakefs_access_key_id.result}"
    secret_access_key     = random_password.lakefs_secret_access_key.result
  })

#   lifecycle {
#     ignore_changes = [secret_string]
#   }
}

resource "random_password" "lakefs_encryption_secret_key" {
  length  = 64
  special = false

  lifecycle {
    ignore_changes = [result]
  }
}

resource "random_password" "lakefs_access_key_id" {
  length  = 16
  special = false
  upper   = true
  lower   = false
  numeric = true

  lifecycle {
    ignore_changes = [result]
  }
}

resource "random_password" "lakefs_secret_access_key" {
  length           = 40
  special          = false

  lifecycle {
    ignore_changes = [result]
  }
} 