resource "aws_launch_template" "lt" {
  name_prefix   = "tylew-asg-template-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = var.security_groups
}

resource "aws_autoscaling_group" "asg" {
  name             = "tylew-asg"
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  vpc_zone_identifier = var.subnets

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
}