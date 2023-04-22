resource "aws_security_group" "load_balancer_security_group" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file

data "template_file" "user_data" {
  template = <<EOF
  #!/bin/bash
  {
    echo "[Unit]"
    echo "Description=Packer custom AMI builder for Spring Boot"
    echo ""
    echo "[Service]"
    echo "User=ec2-user"
    echo "ExecStart=/usr/bin/java -Dspring.config.location=/home/ec2-user/webapp/application.properties -Ddb_endpoint=${aws_db_instance.rds_instance.endpoint} -Ddb_name=${aws_db_instance.rds_instance.db_name} -Ddb_username=${aws_db_instance.rds_instance.username} -Ddb_password=${aws_db_instance.rds_instance.password} -jar /home/ec2-user/webapp/webapp-0.0.1-SNAPSHOT.jar"
    echo ""
    echo "[Install]"
    echo "WantedBy=multi-user.target"
  } >>/home/ec2-user/webapp/application.service
  sudo echo "bucketName=${aws_s3_bucket.s3_bucket.bucket}" >> /home/ec2-user/webapp/application.properties
  sudo mv home/ec2-user/webapp/application.service /etc/systemd/system/application.service
  sudo systemctl daemon-reload
  sudo systemctl enable application.service
  sudo systemctl start application.service
  sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/home/ec2-user/webapp/cloudWatchConfig.json \
    -s
  EOF
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template

resource "aws_launch_template" "lt" {
  name                                 = "webapp-lt"  #this is used in the yml
  user_data                            = base64encode(data.template_file.user_data.rendered)
  instance_type                        = "t2.micro"
  image_id                             = var.ami_id
  key_name                             = "csye6225"
  disable_api_termination              = false
  instance_initiated_shutdown_behavior = "stop"
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_security_group.id]
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.iam_instance_profile.name
  }
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      encrypted  = true
      kms_key_id = aws_kms_key.ebs_key.arn
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group

resource "aws_autoscaling_group" "asg" {
  name                = "csye6225-asg-spring2023"
  default_cooldown    = 60
  max_size            = 3
  min_size            = 1
  desired_capacity    = 1
  target_group_arns   = [aws_lb_target_group.alb_tg.arn]
  vpc_zone_identifier = [for subnet in aws_subnet.public_subnets : subnet.id]
  launch_template {
    id = aws_launch_template.lt.id
  }
  tag {
    key                 = "Cooldown"
    value               = "60"
    propagate_at_launch = true
  }
  tag {
    key                 = "LaunchConfigurationName"
    value               = aws_launch_template.lt.id
    propagate_at_launch = true
  }
  tag {
    key                 = "MinSize"
    value               = "1"
    propagate_at_launch = true
  }
  tag {
    key                 = "MaxSize"
    value               = "3"
    propagate_at_launch = true
  }
  tag {
    key                 = "DesiredCapacity"
    value               = "1"
    propagate_at_launch = true
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy

resource "aws_autoscaling_policy" "scale_up_policy" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  name                   = "webapp-asg-cpu-up"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
}

resource "aws_autoscaling_policy" "scale_down_policy" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  name                   = "webapp-asg-cpu-down"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm_up" {
  alarm_name          = "cpu alarm scale_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 5
  alarm_description   = "ec2 cpu utilization >= 5"
  alarm_actions       = [aws_autoscaling_policy.scale_up_policy.arn]
  dimensions          = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm_down" {
  alarm_name          = "cpu alarm scale_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 3
  alarm_description   = "ec2 cpu utilization <= 3"
  alarm_actions       = [aws_autoscaling_policy.scale_down_policy.arn]
  dimensions          = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb

resource "aws_lb" "lb" {
  name               = "csye6225-lb"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  security_groups    = [aws_security_group.load_balancer_security_group.id]
  subnets            = [for subnet in aws_subnet.public_subnets : subnet.id]
  tags               = {
    Application = "WebApp"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group

resource "aws_lb_target_group" "alb_tg" {
  name             = "csye6225-lb-alb-tg"
  vpc_id           = aws_vpc.main.id
  port             = var.app_port
  target_type      = "instance"
  protocol         = "HTTP"
  protocol_version = "HTTP1"
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 5
    interval            = 30
    path                = "/healthz"
    protocol            = "HTTP"
    port                = var.app_port
    matcher             = 200
    timeout             = 10
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 443
  protocol          = "HTTPS"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
  certificate_arn = var.certificate_arn
}