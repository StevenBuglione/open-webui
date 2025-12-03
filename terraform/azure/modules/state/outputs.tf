output "resource_group_name" {
  description = "Resource group hosting the Terraform state backend."
  value       = azurerm_resource_group.state.name
}

output "storage_account_name" {
  description = "Storage account containing Terraform state blobs."
  value       = azurerm_storage_account.state.name
}

output "storage_account_id" {
  description = "ID of the Terraform state storage account."
  value       = azurerm_storage_account.state.id
}

output "container_name" {
  description = "Blob container name for Terraform state."
  value       = azurerm_storage_container.state.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint for the Terraform state storage account."
  value       = azurerm_storage_account.state.primary_blob_endpoint
}
