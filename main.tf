terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  # Detailed monitoring = 1-minute metrics; basic = 5-minute metrics
  alarm_period = var.detailed_monitoring ? 60 : 300
}

# ---------- Networking (reuses the existing VPC from Project 1) ----------

data "aws_vpc" "existing" {
  id = var.vpc_id
}

resource "aws_subnet" "public" {
  vpc_id                  = data.aws_vpc.existing.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = { Name = "${var.project_name}-public-subnet" }
}

# ---------- Security Group (no inbound rules: no SSH, no 3809) ----------

resource "aws_security_group" "monitored" {
  name        = "${var.project_name}-sg"
  description = "No inbound access; outbound allowed"
  vpc_id      = data.aws_vpc.existing.id

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg" }
}

# ---------- EC2 ----------

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "monitored" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.monitored.id]
  associate_public_ip_address = true
  monitoring                  = var.detailed_monitoring

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    enable_load_test = var.enable_load_test
    load_start_delay = var.load_start_delay_seconds
    load_duration    = var.load_duration_seconds
  })
  user_data_replace_on_change = true

  tags = { Name = "${var.project_name}-ec2" }
}

# ---------- Alerting ----------

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

# Email must be confirmed by clicking the link AWS sends you
resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ---------- CloudWatch Alarm ----------

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name        = "${var.project_name}-cpu-high"
  alarm_description = "CPU above ${var.cpu_threshold}% on ${var.project_name} EC2"

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"
  dimensions = {
    InstanceId = aws_instance.monitored.id
  }

  statistic           = "Average"
  period              = local.alarm_period
  evaluation_periods  = var.evaluation_periods
  threshold           = var.cpu_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}
