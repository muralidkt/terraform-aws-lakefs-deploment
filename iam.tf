resource "aws_iam_role" "lakefs_role" {
  name = "${var.project_name}-${var.environment}-lakefs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_instance_profile" "lakefs_profile" {
  name = "${var.project_name}-${var.environment}-lakefs-profile"
  role = aws_iam_role.lakefs_role.name
}

# Updated the resource references to match the S3 bucket resource name
resource "aws_iam_role_policy" "lakefs_access" {
  name = "${var.project_name}-${var.environment}-lakefs-access"
  role = aws_iam_role.lakefs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          aws_s3_bucket.lakefs.arn,
          "${aws_s3_bucket.lakefs.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:*"
        ]
        Resource = [
          aws_dynamodb_table.lakefs_metadata.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.lakefs_initial_secrets.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lakefs_ssm" {
  role       = aws_iam_role.lakefs_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
} 