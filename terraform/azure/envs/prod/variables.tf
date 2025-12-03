variable "tenant_id" {
  description = "Azure AD tenant ID."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID for this environment."
  type        = string
}

variable "location" {
  description = "Azure region for resources."
  type        = string
}

variable "tags" {
  description = "Common tags applied to Azure resources."
  type        = map(string)
  default     = {}
}

variable "security_resource_group_name" {
  description = "Resource group name for security-centric resources (Key Vault, CA artifacts)."
  type        = string
}

variable "monitoring_resource_group_name" {
  description = "Resource group name for monitoring/logging resources."
  type        = string
}

variable "key_vault_name" {
  description = "Name of the Key Vault to store OpenWebUI secrets."
  type        = string
}

variable "key_vault_private_endpoint_subnet_id" {
  description = "Subnet ID for the Key Vault private endpoint."
  type        = string
  default     = null
}

variable "virtual_network_id" {
  description = "Virtual network ID for private DNS link."
  type        = string
  default     = null
}

variable "log_analytics_workspace_name" {
  description = "Log Analytics workspace name."
  type        = string
}

variable "groups" {
  description = "Group definitions consumed by the groups module."
  type = list(object({
    display_name               = string
    description                = optional(string)
    mail_enabled               = optional(bool, false)
    mail_nickname              = optional(string)
    security_enabled           = optional(bool, true)
    visibility                 = optional(string, "Private")
    owners                     = optional(list(string), [])
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
}

variable "rbac_mappings" {
  description = "Mapping from group display names to OpenWebUI roles and LiteLLM team names."
  type = map(object({
    openwebui_role = string
    lite_llm_team  = string
    description    = optional(string)
    environment    = optional(string)
  }))
}

variable "role_assignments" {
  description = "Directory role assignments for automation principals."
  type = list(object({
    principal_object_id = string
    directory_role_id   = string
  }))
  default = []
}

variable "create_administrative_unit" {
  description = "Whether to create a dedicated Administrative Unit."
  type        = bool
  default     = false
}

variable "administrative_unit_display_name" {
  description = "Display name for the Administrative Unit."
  type        = string
  default     = "OpenWebUI Administrative Unit"
}

variable "openwebui_redirect_uris" {
  description = "Allowed redirect URIs for the OpenWebUI OAuth flow."
  type        = list(string)
}

variable "openwebui_logout_url" {
  description = "Logout URL for OpenWebUI."
  type        = string
  default     = null
}

variable "openwebui_identifier_uris" {
  description = "Optional identifier URIs for the OpenWebUI application."
  type        = list(string)
  default     = []
}

variable "openwebui_app_roles" {
  description = "Optional app roles to expose via the OpenWebUI application."
  type = list(object({
    allowed_member_types = list(string)
    description          = string
    display_name         = string
    value                = string
    enabled              = optional(bool, true)
    id                   = optional(string)
  }))
  default = []
}

variable "scim_base_address" {
  description = "SCIM endpoint base address."
  type        = string
}

variable "scim_secret_token" {
  description = "SCIM bearer token."
  type        = string
  sensitive   = true
}

variable "scim_template_id" {
  description = "SCIM synchronization template ID."
  type        = string
}

variable "scim_enabled" {
  description = "Enable SCIM provisioning."
  type        = bool
  default     = true
}

variable "lite_llm_application_enabled" {
  description = "Whether to create a LiteLLM app registration."
  type        = bool
  default     = true
}

variable "lite_llm_identifier_uris" {
  description = "Optional identifier URIs for the LiteLLM app registration."
  type        = list(string)
  default     = []
}

variable "lite_llm_display_name" {
  description = "Display name for the LiteLLM app registration."
  type        = string
  default     = "LiteLLM Service"
}

variable "conditional_access_policies" {
  description = "List of conditional access policies to enforce."
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
      sign_in_risk_levels = optional(list(string), [])
      user_risk_levels    = optional(list(string), [])
    }))
  }))
  default = []
}

variable "diagnostic_sources" {
  description = "Diagnostic sources (resource IDs) to export to Log Analytics."
  type = list(object({
    name              = string
    resource_id       = string
    log_categories    = optional(list(string), [])
    metric_categories = optional(list(string), [])
  }))
  default = []
}

variable "key_vault_rbac_assignments" {
  description = "Principals to grant Key Vault RBAC permissions."
  type = list(object({
    principal_id         = string
    role_definition_name = optional(string, "Key Vault Secrets Officer")
    role_definition_id   = optional(string)
  }))
  default = []
}
