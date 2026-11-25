variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix used in resource names and tags"
  type        = string
  default     = "capstone-p3"
}

variable "vpc_id" {
  description = "Existing VPC to deploy into"
  type        = string
  default     = "vpc-04cceb7bf4db0d5b4"
}

variable "subnet_cidr" {
  description = "New subnet CIDR: inside the VPC range, not overlapping existing subnets"
  type        = string
  default     = "10.0.2.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "alert_email" {
  description = "Email for alarm notifications. Leave empty to skip the subscription."
  type        = string
  default     = ""
}

variable "cpu_threshold" {
  description = "CPU utilization (%) above which the alarm fires"
  type        = number
  default     = 70
}

variable "evaluation_periods" {
  description = "Consecutive periods the threshold must be breached"
  type        = number
  default     = 2
}

variable "detailed_monitoring" {
  description = "true = 1-minute metrics (small extra cost); false = free 5-minute metrics"
  type        = bool
  default     = true
}

variable "enable_load_test" {
  description = "Run an automatic CPU load after boot"
  type        = bool
  default     = true
}

variable "load_start_delay_seconds" {
  description = "Wait before load starts (time to screenshot the OK state)"
  type        = number
  default     = 300
}

variable "load_duration_seconds" {
  description = "How long the CPU load runs"
  type        = number
  default     = 900
}
