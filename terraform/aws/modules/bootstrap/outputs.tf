output "state_bucket" {
  value       = aws_s3_bucket.state.id
  description = "Terraform state bucket name."
}

output "lock_table" {
  value       = aws_dynamodb_table.lock.name
  description = "Terraform lock table name."
}

output "kms_key_arn" {
  value       = aws_kms_key.state.arn
  description = "KMS key arn used for state bucket encryption."
}
