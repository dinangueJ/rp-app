# -----------------------------
# Launch Template
# -----------------------------
resource "aws_launch_template" "rp_template" {
  name_prefix   = "rp-template"
  image_id      = "ami-00e801948462f718a"   # 🔁 Replace with Amazon Linux 2023 AMI ID
  instance_type = "t3.micro"

  iam_instance_profile {
    name = "rp-ec2-role"
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.rp_ec2_sg.id]
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name    = "rp-asg-instance"
      Project = "ResumePortal"
    }
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
set -e
exec > >(tee /var/log/user-data.log) 2>&1

dnf update -y
dnf install -y python3 python3-pip git nginx postgresql15 gcc python3-devel libpq-devel

mkdir -p /opt/rp-app
cd /opt/rp-app
git clone https://github.com/dinangueJ/rp-app.git .

python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

chown -R ec2-user:ec2-user /opt/rp-app

cp /opt/rp-app/deploy/rp-app.service /etc/systemd/system/
cp /opt/rp-app/deploy/rp-app.conf /etc/nginx/conf.d/

touch /var/log/rp-app-access.log /var/log/rp-app-error.log
chown ec2-user:ec2-user /var/log/rp-app-*.log

systemctl daemon-reload
systemctl enable nginx rp-app
systemctl start nginx rp-app

echo "OK" > /tmp/bootstrap-success
EOF
  )
}

# -----------------------------
# Auto Scaling Group
# -----------------------------
resource "aws_autoscaling_group" "rp_asg" {
  name                      = "rp-asg"
  desired_capacity          = 2
  min_size                  = 2
  max_size                  = 4
  vpc_zone_identifier = [
  aws_subnet.rp_private_1a.id,
  aws_subnet.rp_private_1b.id
]

  target_group_arns = [aws_lb_target_group.rp_targets.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.rp_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "rp-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "ResumePortal"
    propagate_at_launch = true
  }
}

# -----------------------------
# Scaling Policy (CPU target tracking)
# -----------------------------
resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.rp_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value       = 70.0
  }
}