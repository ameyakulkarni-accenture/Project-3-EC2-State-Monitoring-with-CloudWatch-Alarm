output "instance_id" {
  description = "ID of the monitored EC2 instance"
  value       = aws_instance.monitored.id
}

output "alarm_name" {
  description = "Name of the CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.cpu_high.alarm_name
}

output "sns_topic_arn" {
  description = "SNS topic that receives alarm notifications"
  value       = aws_sns_topic.alerts.arn
}

output "alarm_console_url" {
  description = "Open this to screenshot the alarm"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#alarmsV2:alarm/${aws_cloudwatch_metric_alarm.cpu_high.alarm_name}"
}
