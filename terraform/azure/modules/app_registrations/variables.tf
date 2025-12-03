variable "tenant_id" {
  description = "Azure AD tenant ID."
  type        = string
}

variable "openid_application" {
  description = "Configuration for the primary OpenWebUI OIDC application."
  type = object({
    display_name            = string
    redirect_uris           = list(string)
    logout_url              = optional(string)
    identifier_uris         = optional(list(string))
    group_membership_claims = optional(list(string), ["SecurityGroup"])
    sign_in_audience        = optional(string, "AzureADMyOrg")
    app_roles = optional(list(object({
      allowed_member_types = list(string)
      description          = string
      display_name         = string
      value                = string
      enabled              = optional(bool, true)
      id                   = optional(string)
    })), [])
  })
}

variable "scim_application" {
  description = "Configuration for the SCIM provisioning application."
  type = object({
    enabled          = bool
    display_name     = string
    identifier_uris  = optional(list(string))
    sign_in_audience = optional(string, "AzureADMyOrg")
  })
  default = {
    enabled          = true
    display_name     = "OpenWebUI SCIM"
    identifier_uris  = null
    sign_in_audience = "AzureADMyOrg"
  }
}

variable "lite_llm_application" {
  description = "Optional app registration for LiteLLM / Bedrock proxy access. When disabled this module will not create additional app registrations."
  type = object({
    enabled          = bool
    display_name     = string
    identifier_uris  = optional(list(string))
    sign_in_audience = optional(string, "AzureADMyOrg")
  })
  default = {
    enabled          = false
    display_name     = "LiteLLM Service"
    identifier_uris  = null
    sign_in_audience = "AzureADMyOrg"
  }
}

variable "password_rotation_days" {
  description = "Validity period for generated client secrets."
  type        = number
  default     = 365
}
