output "openwebui_application" {
  description = "Identifiers for the OpenWebUI app registration."
  value = {
    client_id     = module.app_registrations.openid.client_id
    object_id     = module.app_registrations.openid.object_id
    sp_object_id  = module.app_registrations.openid.service_principal_id
    client_secret = module.app_registrations.openid.client_secret
    app_role_ids  = module.app_registrations.openid.app_role_ids
  }
  sensitive = true
}

output "group_object_ids" {
  description = "Map of RBAC group names to object IDs."
  value       = module.groups.groups
}

output "rbac_mapping" {
  description = "Computed RBAC mapping consumed by AWS/OpenWebUI."
  value       = module.rbac_mapping.openwebui_group_mappings
}

output "key_vault_uri" {
  description = "URI of the Key Vault storing OpenWebUI secrets."
  value       = null
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for Entra diagnostics."
  value       = module.monitoring.workspace_id
}
