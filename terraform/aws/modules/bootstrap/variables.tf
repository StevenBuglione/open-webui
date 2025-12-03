variable "name_prefix" {
  description = "Short prefix applied to bootstrap resources."
  type        = string
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket that will store Terraform state."
  type        = string
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
