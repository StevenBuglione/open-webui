variable "aws_profile" {
  description = "AWS CLI profile."
  type        = string
  default     = "default"
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (nonprod/prod)."
  type        = string
}

variable "tags" {
  description = "Base tags."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
}

variable "availability_zones" {
  description = "List of AZs."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets."
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT per AZ."
  type        = bool
  default     = true
}

variable "alb_ingress_cidrs" {
  description = "CIDRs allowed to reach ALB."
  type        = list(string)
}

variable "database_username" {
  description = "Database master username."
  type        = string
  default     = "openwebui"
}

variable "database_name" {
  description = "Database name."
  type        = string
  default     = "openwebui"
}

variable "database_instance_class" {
  description = "DB instance class."
  type        = string
}

variable "database_allocated_storage" {
  description = "DB storage (GB)."
  type        = number
}

variable "database_engine_version" {
  description = "Postgres version."
  type        = string
  default     = "15.15"
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
  description = "Retention days."
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot."
  type        = bool
  default     = false
}

variable "openwebui_container_image" {
  description = "Container image for OpenWebUI."
  type        = string
}

variable "openwebui_container_port" {
  description = "OpenWebUI container port."
  type        = number
  default     = 8080
}

variable "openwebui_desired_count" {
  description = "Desired task count."
  type        = number
  default     = 2
}

variable "openwebui_cpu" {
  description = "CPU units."
  type        = number
  default     = 1024
}

variable "openwebui_memory" {
  description = "Memory (MB)."
  type        = number
  default     = 2048
}

variable "openwebui_env" {
  description = "Plain environment variables for OpenWebUI."
  type        = map(string)
}

variable "openwebui_oidc_client_secret" {
  description = "OIDC client secret value stored in Secrets Manager. Leave empty to use a placeholder and update manually."
  type        = string
  default     = ""
  sensitive   = true
}

variable "openwebui_scim_token" {
  description = "SCIM token value stored in Secrets Manager. Leave empty to use a placeholder and update manually."
  type        = string
  default     = ""
  sensitive   = true
}

variable "openwebui_secret_arns" {
  description = "Secret references for OpenWebUI."
  type = list(object({
    name       = string
    value_from = string
  }))
  default = []
}

variable "litellm_container_image" {
  description = "LiteLLM image."
  type        = string
}

variable "litellm_container_port" {
  description = "LiteLLM port."
  type        = number
  default     = 4000
}

variable "litellm_env" {
  description = "LiteLLM env map."
  type        = map(string)
  default     = {}
}

variable "litellm_config_secret" {
  description = "LiteLLM configuration JSON that will be stored in Secrets Manager."
  type        = string
  default     = "{}"
  sensitive   = true
}

variable "litellm_secrets" {
  description = "LiteLLM secret refs."
  type = list(object({
    name       = string
    value_from = string
  }))
  default = []
}

variable "litellm_internal_url" {
  description = "Internal URL for OpenWebUI to reach LiteLLM."
  type        = string
}

variable "mcpo_container_image" {
  description = "mcpo image."
  type        = string
}

variable "mcpo_container_port" {
  description = "mcpo port."
  type        = number
  default     = 8081
}

variable "mcpo_env" {
  description = "mcpo env map."
  type        = map(string)
  default     = {}
}

variable "enable_mcpo" {
  description = "Whether to run the mcpo proxy service."
  type        = bool
  default     = false
}

variable "mcpo_config_secret" {
  description = "mcpo configuration JSON stored in Secrets Manager."
  type        = string
  default     = "{}"
  sensitive   = true
}

variable "mcpo_secrets" {
  description = "mcpo secret refs."
  type = list(object({
    name       = string
    value_from = string
  }))
  default = []
}

variable "log_retention_in_days" {
  description = "Log retention."
  type        = number
  default     = 30
}

variable "enable_cloudflare_dns" {
  description = "Enable Cloudflare DNS automation."
  type        = bool
  default     = false
}

variable "cloudflare_api_token" {
  description = "API token for Cloudflare automation."
  type        = string
  default     = ""
  sensitive   = true

  validation {
    condition     = (!var.enable_cloudflare_dns && !var.use_managed_certificate) || var.cloudflare_api_token != ""
    error_message = "Provide a Cloudflare API token when DNS automation or managed certificates are enabled."
  }
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone id."
  type        = string
  default     = ""
}

variable "cloudflare_record_name" {
  description = "Cloudflare record name."
  type        = string
  default     = ""
}

variable "certificate_domain_name" {
  description = "Primary domain for ACM cert."
  type        = string
  default     = ""
}

variable "certificate_san" {
  description = "Additional SANs."
  type        = list(string)
  default     = []
}

variable "use_managed_certificate" {
  description = "Whether to create/manage ACM certificate."
  type        = bool
  default     = false

  validation {
    condition     = var.use_managed_certificate ? var.enable_cloudflare_dns : true
    error_message = "Enable Cloudflare DNS automation to manage ACM certificates."
  }
}

variable "existing_certificate_arn" {
  description = "Existing ACM certificate ARN (used when use_managed_certificate=false)."
  type        = string
  default     = ""

  validation {
    condition     = var.use_managed_certificate || var.existing_certificate_arn != ""
    error_message = "Provide an existing_certificate_arn or enable use_managed_certificate."
  }
}

variable "alarm_topic_arns" {
  description = "External SNS alarm ARNs."
  type        = list(string)
  default     = []
}

variable "create_alarm_topic" {
  description = "Create SNS topic."
  type        = bool
  default     = true
}
