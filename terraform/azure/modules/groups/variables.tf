variable "groups" {
  description = "List of groups to create for OpenWebUI RBAC."
  type = list(object({
    display_name               = string
    description                = optional(string)
    mail_enabled               = optional(bool, false)
    mail_nickname              = optional(string)
    security_enabled           = optional(bool, true)
    visibility                 = optional(string, "Private")
    owners                     = optional(list(string))
    members                    = optional(list(string), [])
    behaviors                  = optional(list(string), [])
    types                      = optional(list(string), [])
    assignable_to_role         = optional(bool, false)
    auto_subscribe_new_members = optional(bool, false)
    external_senders_allowed   = optional(bool, false)
    dynamic_membership = optional(object({
      enabled = bool
      rule    = string
    }))
  }))
  default = []
}

variable "administrative_unit_id" {
  description = "Administrative Unit ID to scope the created groups (optional)."
  type        = string
  default     = null
}

variable "prevent_duplicate_names" {
  description = "Whether to prevent creation when a group with the same name already exists."
  type        = bool
  default     = true
}
