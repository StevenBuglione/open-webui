variable "resource_group_name" {
  description = "Resource group hosting the Key Vault."
  type        = string
}

variable "location" {
  description = "Azure region for the Key Vault."
  type        = string
}

variable "key_vault_name" {
  description = "Name of the Key Vault (must be globally unique)."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID."
  type        = string
}

variable "sku_name" {
  description = "Key Vault SKU (standard or premium)."
  type        = string
  default     = "standard"
}

variable "tags" {
  description = "Tags applied to Key Vault resources."
  type        = map(string)
  default     = {}
}

variable "log_analytics_workspace_id" {
  description = "Optional Log Analytics workspace ID for diagnostics."
  type        = string
  default     = null
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the Key Vault private endpoint (optional)."
  type        = string
  default     = null
}

variable "virtual_network_id" {
  description = "Virtual network ID to link to the private DNS zone (required when creating a private endpoint)."
  type        = string
  default     = null
}

variable "create_private_dns_zone" {
  description = "Whether to create a private DNS zone for the Key Vault private endpoint."
  type        = bool
  default     = true
}

variable "existing_private_dns_zone_id" {
  description = "Optional existing private DNS zone ID for privatelink.vaultcore.azure.net."
  type        = string
  default     = null
}

variable "secrets" {
  description = "Map of secrets to create in the Key Vault."
  type = map(object({
    value        = string
    content_type = optional(string)
  }))
  default = {}
}

variable "secret_names" {
  description = "List of secret names (non-sensitive) corresponding to the provided secrets map."
  type        = list(string)
  default     = []
}

variable "rbac_assignments" {
  description = "RBAC assignments granting access to the Key Vault."
  type = list(object({
    principal_id         = string
    role_definition_name = optional(string, "Key Vault Secrets Officer")
    role_definition_id   = optional(string)
  }))
  default = []
}
