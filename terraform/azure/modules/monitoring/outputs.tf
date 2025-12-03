output "workspace_id" {
  description = "Log Analytics workspace ID."
  value       = azurerm_log_analytics_workspace.this.id
}

output "workspace_customer_id" {
  description = "Log Analytics workspace customer ID."
  value       = azurerm_log_analytics_workspace.this.workspace_id
}

output "workspace_primary_shared_key" {
  description = "Primary shared key for the workspace."
  value       = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive   = true
}
