variable "resource_group_name" {
  description = "Resource group for monitoring resources."
  type        = string
}

variable "location" {
  description = "Azure region for monitoring resources."
  type        = string
}

variable "workspace_name" {
  description = "Name of the Log Analytics workspace."
  type        = string
}

variable "retention_in_days" {
  description = "Retention period for workspace data."
  type        = number
  default     = 365
}

variable "diagnostic_sources" {
  description = "List of diagnostic sources to connect to the workspace."
  type = list(object({
    name              = string
    resource_id       = string
    log_categories    = optional(list(string), [])
    metric_categories = optional(list(string), [])
  }))
  default = []
}
