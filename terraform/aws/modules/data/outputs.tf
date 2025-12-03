output "db_instance_id" {
  value       = aws_db_instance.this.id
  description = "RDS instance identifier."
}

output "db_endpoint" {
  value       = aws_db_instance.this.address
  description = "RDS endpoint."
}

output "db_port" {
  value       = aws_db_instance.this.port
  description = "RDS port."
}

output "db_credentials_secret_arn" {
  value       = aws_secretsmanager_secret.db_credentials.arn
  description = "Secrets Manager ARN storing DB username/password."
}

output "database_url_secret_arn" {
  value       = aws_secretsmanager_secret.db_url.arn
  description = "Secrets Manager ARN storing DATABASE_URL."
}

output "efs_file_system_id" {
  value       = aws_efs_file_system.this.id
  description = "EFS filesystem ID."
}

output "efs_access_point_id" {
  value       = aws_efs_access_point.openwebui.id
  description = "EFS access point for OpenWebUI."
}
