resource "aws_dynamodb_table" "lakefs_metadata" {
  name           = coalesce(var.dynamodb_table_name, "${var.project_name}-${var.environment}-lakefs-metadata")
  billing_mode   = "PAY_PER_REQUEST"  # This is On-demand mode
  hash_key       = "PartitionKey"
  range_key      = "ItemKey"

  attribute {
    name = "PartitionKey"
    type = "B"  # Binary type
  }

  attribute {
    name = "ItemKey"
    type = "B"  # Binary type
  }

  # Secondary index for version inventory
  global_secondary_index {
    name            = "version-path-index"
    hash_key        = "ItemKey"
    range_key       = "PartitionKey"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = var.dynamodb_point_in_time_recovery
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-lakefs-metadata"
      Environment = var.environment
    },
    var.tags
  )
}

# Add DynamoDB access to the LakeFS IAM role
resource "aws_iam_role_policy" "lakefs_dynamodb_access" {
  name = "${var.project_name}-${var.environment}-dynamodb-policy"
  role = aws_iam_role.lakefs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_dynamodb_table.lakefs_metadata.arn,
          "${aws_dynamodb_table.lakefs_metadata.arn}/*"
        ]
      }
    ]
  })
} 