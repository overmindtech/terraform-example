#
# Test Case 1
#

# Define an EC2 launch template
resource "aws_launch_template" "my_launch_template" {
  name_prefix   = "asg-change-launch-template-${var.example_env}"
  image_id      = var.ami_id
  instance_type = "t3.micro"
  vpc_security_group_ids = [var.default_security_group_id]
}

# Create a Target Group
resource "aws_lb_target_group" "my_target_group" {
  name     = "asg-change-tg-${var.example_env}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path = "/"
  }
}

# Create a second Target Group
resource "aws_lb_target_group" "my_new_target_group" {
  name     = "asg-new-${var.example_env}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path = "/"
  }
}

# Create an Auto Scaling Group
resource "aws_autoscaling_group" "my_asg" {
  name                      = "asg-change-test-asg-${var.example_env}"
  min_size                  = 0
  max_size                  = 2
  desired_capacity          = 1
  target_group_arns         = [aws_lb_target_group.my_target_group.arn]
  vpc_zone_identifier       = var.public_subnets
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.my_launch_template.id
    version = "$Latest"
  }
}

