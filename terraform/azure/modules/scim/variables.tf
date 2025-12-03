variable "enabled" {
  description = "Whether to configure the SCIM synchronization job."
  type        = bool
  default     = true
}

variable "service_principal_id" {
  description = "Object ID of the SCIM service principal."
  type        = string
}

variable "base_address" {
  description = "SCIM endpoint base address (e.g. https://owui.example.com/scim)."
  type        = string
}

variable "secret_token" {
  description = "Bearer token to authenticate SCIM provisioning calls."
  type        = string
  sensitive   = true
}

variable "template_id" {
  description = "Synchronization template ID to use (e.g. the ID for the generic SCIM template)."
  type        = string
}
