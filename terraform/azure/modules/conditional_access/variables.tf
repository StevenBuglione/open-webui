variable "policies" {
  description = "List of conditional access policies to enforce for OpenWebUI applications."
  type = list(object({
    display_name         = string
    state                = string
    include_applications = list(string)
    include_groups       = list(string)
    exclude_groups       = optional(list(string), [])
    client_app_types     = optional(list(string), ["all"])
    grant_controls = object({
      operator          = optional(string, "AND")
      built_in_controls = list(string)
    })
    session_controls = optional(object({
      application_enforced_restrictions = optional(bool, false)
      persist_browser_session           = optional(string)
      sign_in_frequency_days            = optional(number)
    }))
    locations = optional(object({
      include_locations = optional(list(string), [])
      exclude_locations = optional(list(string), [])
    }))
    platforms = optional(object({
      include_platforms = optional(list(string), [])
      exclude_platforms = optional(list(string), [])
    }))
    conditions = optional(object({
      sign_in_risk_levels       = optional(list(string), [])
      user_risk_levels          = optional(list(string), [])
      device_states             = optional(object({ include = list(string), exclude = list(string) }), null)
      require_compliant_devices = optional(bool, false)
      require_hybrid_joined     = optional(bool, false)
    }))
  }))
  default = []
}
