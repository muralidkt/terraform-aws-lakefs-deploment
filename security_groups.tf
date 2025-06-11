resource "aws_security_group" "lakefs" {
  name        = "${var.project_name}-${var.environment}-lakefs-instance-sg"
  description = "Security group for LakeFS instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "LakeFS API and UI access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-lakefs-instance-sg"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-lakefs-alb-sg"
  description = "Security group for LakeFS ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-lakefs-alb-sg"
      Environment = var.environment
    },
    var.tags
  )
} 