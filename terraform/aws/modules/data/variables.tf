variable "name" {
  description = "Prefix for data resources."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for RDS/EFS."
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "Security group ID for RDS."
  type        = string
}

variable "efs_security_group_id" {
  description = "Security group ID for EFS."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption."
  type        = string
}

variable "database_username" {
  description = "Database master username."
  type        = string
}

variable "database_name" {
  description = "Database name."
  type        = string
  default     = ""
}

variable "database_instance_class" {
  description = "Instance class for RDS."
  type        = string
}

variable "database_allocated_storage" {
  description = "Storage size in GB."
  type        = number
}

variable "database_engine_version" {
  description = "Postgres engine version."
  type        = string
  default     = "15.4"
}

variable "database_multi_az" {
  description = "Enable multi-AZ."
  type        = bool
  default     = true
}

variable "database_deletion_protection" {
  description = "Enable deletion protection."
  type        = bool
  default     = true
}

variable "database_backup_retention_days" {
  description = "Backup retention period."
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
