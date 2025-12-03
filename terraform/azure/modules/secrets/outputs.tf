output "key_vault_id" {
  description = "ID of the created Key Vault."
  value       = azurerm_key_vault.this.id
}

output "key_vault_uri" {
  description = "Vault URI used by clients."
  value       = azurerm_key_vault.this.vault_uri
}

output "private_endpoint_id" {
  description = "ID of the private endpoint (if created)."
  value       = try(azurerm_private_endpoint.kv[0].id, null)
}
