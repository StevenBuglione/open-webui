variable "name" {
  description = "Prefix for observability resources."
  type        = string
}

variable "rds_instance_id" {
  description = "RDS instance identifier."
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix."
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name."
  type        = string
}

variable "ecs_service_name" {
  description = "Primary ECS service name."
  type        = string
}

variable "alarm_topic_arns" {
  description = "Optional list of SNS ARNs for alarms."
  type        = list(string)
  default     = []
}

variable "create_alarm_topic" {
  description = "Whether to create a dedicated SNS topic."
  type        = bool
  default     = true
}

variable "rds_cpu_threshold" {
  description = "CPU threshold percentage."
  type        = number
  default     = 80
}

variable "alb_5xx_threshold" {
  description = "Count threshold for ALB 5xx."
  type        = number
  default     = 25
}

variable "ecs_memory_threshold" {
  description = "ECS memory utilization threshold."
  type        = number
  default     = 85
}

variable "tags" {
  description = "Tags."
  type        = map(string)
  default     = {}
}
