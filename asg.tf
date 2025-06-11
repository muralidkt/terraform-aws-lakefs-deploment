# Scale down to 0 on Friday evenings
resource "aws_autoscaling_schedule" "scale_down" {
  count                  = var.environment != "prod" ? 1 : 0
  scheduled_action_name  = "${var.project_name}-${var.environment}-lakefs-scale-down"
  min_size              = 0
  max_size              = 0
  desired_capacity      = 0
  recurrence           = "0 20 * * FRI"  # Friday at 20:00 UTC
  time_zone            = "UTC"
  autoscaling_group_name = aws_autoscaling_group.lakefs.name
}

# Scale up on Monday mornings
resource "aws_autoscaling_schedule" "scale_up" {
  count                  = var.environment != "prod" ? 1 : 0
  scheduled_action_name  = "${var.project_name}-${var.environment}-lakefs-scale-up"
  min_size              = var.asg_min_size
  max_size              = var.asg_max_size
  desired_capacity      = var.asg_desired_capacity
  recurrence           = "0 6 * * MON"  # Monday at 06:00 UTC
  time_zone            = "UTC"
  autoscaling_group_name = aws_autoscaling_group.lakefs.name
}

# Additional schedule for scaling down on weekday nights (optional)
resource "aws_autoscaling_schedule" "scale_down_nightly" {
  count                  = var.enable_nightly_shutdown ? 1 : 0
  scheduled_action_name  = "${var.project_name}-${var.environment}-lakefs-scale-down-nightly"
  min_size              = 0
  max_size              = 0
  desired_capacity      = 0
  recurrence           = "0 20 * * MON-FRI"  # Monday-Friday at 20:00 UTC
  time_zone            = "UTC"
  autoscaling_group_name = aws_autoscaling_group.lakefs.name
}

# Additional schedule for scaling up on weekday mornings (optional)
resource "aws_autoscaling_schedule" "scale_up_daily" {
  count                  = var.enable_nightly_shutdown ? 1 : 0
  scheduled_action_name  = "${var.project_name}-${var.environment}-lakefs-scale-up-daily"
  min_size              = var.asg_min_size
  max_size              = var.asg_max_size
  desired_capacity      = var.asg_desired_capacity
  recurrence           = "0 6 * * MON-FRI"  # Monday-Friday at 06:00 UTC
  time_zone            = "UTC"
  autoscaling_group_name = aws_autoscaling_group.lakefs.name
}

# Launch Template
resource "aws_launch_template" "lakefs" {
  name_prefix   = "${var.project_name}-${var.environment}-lakefs-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [aws_security_group.lakefs.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.lakefs_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/userdata/lakefs_setup.sh", {
    lakefs_version     = var.lakefs_version
    region            = var.aws_region
    dynamodb_table_name = aws_dynamodb_table.lakefs_metadata.name
    lakefs_bucket     = var.lakefs_bucket
    project_name      = var.project_name
    environment       = var.environment
  }))

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp3"
      encrypted   = true
    }
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      {
        Name        = "${var.project_name}-${var.environment}-lakefs"
        Environment = var.environment
      },
      var.tags
    )
  }

  update_default_version = true

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "lakefs" {
  name                = "${var.project_name}-${var.environment}-lakefs-asg"
  desired_capacity    = var.asg_desired_capacity
  max_size           = var.asg_max_size
  min_size           = var.asg_min_size
  target_group_arns  = [aws_lb_target_group.lakefs.arn]
  vpc_zone_identifier = var.private_subnet_ids
  health_check_grace_period = var.health_check_grace_period
  health_check_type  = "ELB"

  launch_template {
    id      = aws_launch_template.lakefs.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(
      {
        Name        = "${var.project_name}-${var.environment}-lakefs"
        Environment = var.environment
      },
      var.tags
    )
    content {
      key                 = tag.key
      value              = tag.value
      propagate_at_launch = true
    }
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup = 300
    }
    triggers = ["tag", "launch_template"]
  }

  lifecycle {
    create_before_destroy = true
  }
} 