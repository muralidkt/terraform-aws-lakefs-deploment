resource "aws_lb" "lakefs" {
  name               = "${var.project_name}-${var.environment}-lakefs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.environment == "prod"

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-lakefs-alb"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_lb_target_group" "lakefs" {
  name     = "${var.project_name}-${var.environment}-lakefs-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher            = "200"
    path               = "/auth/login"
    port               = "traffic-port"
    timeout            = 5
    unhealthy_threshold = 2
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-lakefs-tg"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.lakefs.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lakefs.arn
  }
}

resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.lakefs.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
} 