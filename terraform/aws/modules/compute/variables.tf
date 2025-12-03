variable "name" {
  description = "Name prefix for compute resources."
  type        = string
}

variable "region" {
  description = "AWS region for log configuration."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC identifier."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for ALB."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnets for ECS services."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group for ALB."
  type        = string
}

variable "service_security_group_id" {
  description = "Security group for ECS services."
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key for log encryption."
  type        = string
}

variable "log_retention_in_days" {
  description = "Log group retention."
  type        = number
  default     = 30
}

variable "services" {
  description = "Map of ECS services definitions."
  type = map(object({
    container_image   = string
    container_port    = number
    desired_count     = number
    cpu               = number
    memory            = number
    attach_to_alb     = bool
    path_patterns     = optional(list(string))
    health_check_path = optional(string)
    env               = optional(map(string))
    secrets = optional(list(object({
      name       = string
      value_from = string
    })))
    efs_volume = optional(object({
      file_system_id     = string
      access_point_id    = optional(string)
      root_directory     = optional(string)
      container_path     = optional(string)
      read_only          = optional(bool)
      transit_encryption = optional(bool)
      use_iam            = optional(bool)
    }))
    entry_point = optional(list(string))
    command     = optional(list(string))
  }))
}

variable "primary_service" {
  description = "Service key that receives default ALB traffic."
  type        = string
}
