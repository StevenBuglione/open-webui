variable "create_administrative_unit" {
  description = "Whether to create a dedicated Administrative Unit for OpenWebUI governance."
  type        = bool
  default     = false
}

variable "administrative_unit_display_name" {
  description = "Display name for the Administrative Unit (if created)."
  type        = string
  default     = "OpenWebUI Administrative Unit"
}

variable "administrative_unit_description" {
  description = "Description for the Administrative Unit."
  type        = string
  default     = "Scope OpenWebUI objects and delegate limited administration."
}

variable "role_assignments" {
  description = "Directory role assignments to grant to automation principals."
  type = list(object({
    principal_object_id           = string
    directory_role_id             = string
    administrative_unit_object_id = optional(string)
  }))
  default = []
}
