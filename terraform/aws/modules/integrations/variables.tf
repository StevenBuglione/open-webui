variable "ssm_parameters" {
  description = "Map of SSM parameter definitions."
  type = map(object({
    value       = string
    description = optional(string)
    type        = optional(string, "String")
  }))
  default = {}
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
