output "ecs_cluster_name" {
  value       = aws_ecs_cluster.this.name
  description = "ECS cluster name."
}

output "alb_dns_name" {
  value       = aws_lb.this.dns_name
  description = "ALB DNS name."
}

output "alb_zone_id" {
  value       = aws_lb.this.zone_id
  description = "ALB hosted zone id."
}

output "alb_arn" {
  value       = aws_lb.this.arn
  description = "ALB ARN."
}

output "alb_arn_suffix" {
  value       = aws_lb.this.arn_suffix
  description = "ALB ARN suffix."
}

output "service_names" {
  value       = [for name, _ in var.services : "${var.name}-${name}"]
  description = "ECS service names."
}

output "task_role_arn" {
  value       = aws_iam_role.task.arn
  description = "IAM role ARN used by ECS tasks."
}

output "task_role_name" {
  value       = aws_iam_role.task.name
  description = "IAM role name used by ECS tasks."
}

output "execution_role_arn" {
  value       = aws_iam_role.execution.arn
  description = "IAM role ARN for ECS execution role."
}
