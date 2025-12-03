variable "resource_group_name" {
  description = "Name of the resource group for Terraform state resources."
  type        = string
}

variable "location" {
  description = "Azure region for the state resources."
  type        = string
}

variable "storage_account_name" {
  description = "Globally unique Storage Account name for Terraform state."
  type        = string
}

variable "container_name" {
  description = "Blob container name to store the Terraform state files."
  type        = string
  default     = "tfstate"
}

variable "tags" {
  description = "Tags to apply to state resources."
  type        = map(string)
  default     = {}
}

variable "customer_managed_key_id" {
  description = "Optional Key Vault key ID for customer-managed encryption of the Storage Account."
  type        = string
  default     = null
}

variable "customer_managed_identity_id" {
  description = "Optional user-assigned managed identity ID used with the customer-managed key."
  type        = string
  default     = null
}
