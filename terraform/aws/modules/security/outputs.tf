output "kms_key_arn" {
  value       = aws_kms_key.workload.arn
  description = "Workload KMS key ARN."
}

output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "ALB security group ID."
}

output "ecs_service_security_group_id" {
  value       = aws_security_group.ecs_service.id
  description = "ECS service security group ID."
}

output "rds_security_group_id" {
  value       = aws_security_group.rds.id
  description = "RDS security group ID."
}

output "efs_security_group_id" {
  value       = aws_security_group.efs.id
  description = "EFS security group ID."
}
