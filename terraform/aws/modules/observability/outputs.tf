output "alarm_topic_arn" {
  value       = try(aws_sns_topic.alerts[0].arn, null)
  description = "SNS topic ARN for alarms (if created)."
}
