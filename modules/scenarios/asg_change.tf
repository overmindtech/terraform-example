#
# Test Case 1
#

# Define an EC2 launch template
resource "aws_launch_template" "my_launch_template" {
  name_prefix   = "asg-change-launch-template"
  image_id      = "ami-0171207a7acd2a570"
  instance_type = "t2.micro"
}

# Create a Target Group
resource "aws_lb_target_group" "my_target_group" {
  name        = "asg-change-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id

  health_check {
    path = "/"
    }
  }

  # Create a second Target Group
resource "aws_lb_target_group" "my_new_target_group" {
  name        = "asg-new-change-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id

  health_check {
    path = "/"
    }
  }

# Create an Auto Scaling Group
resource "aws_autoscaling_group" "my_asg" {
  name                 = "asg-change-test-asg"
  min_size             = 0
  max_size             = 2
  desired_capacity     = 1
  target_group_arns    = [aws_lb_target_group.my_new_target_group.arn]
  availability_zones   = ["eu-west-2a"]  # Replace with your desired AZs
  health_check_type    = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.my_launch_template.id
    version = "$Latest"
  }
}
