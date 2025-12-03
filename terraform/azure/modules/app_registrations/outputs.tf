output "openid" {
  description = "Metadata for the OpenWebUI OIDC application."
  value = {
    client_id            = azuread_application.openid.client_id
    object_id            = azuread_application.openid.id
    service_principal_id = azuread_service_principal.openid.id
    client_secret        = azuread_application_password.openid.value
    app_role_ids         = azuread_application.openid.app_role_ids
  }
  sensitive = true
}

output "scim" {
  description = "Metadata for the SCIM provisioning application (if enabled)."
  value = var.scim_application.enabled ? {
    client_id            = azuread_application.scim[0].client_id
    object_id            = azuread_application.scim[0].id
    service_principal_id = azuread_service_principal.scim[0].id
    client_secret        = azuread_application_password.scim[0].value
  } : null
  sensitive = true
}

output "litellm" {
  description = "Metadata for the LiteLLM proxy application (if enabled)."
  value = var.lite_llm_application.enabled ? {
    client_id            = azuread_application.litellm[0].client_id
    object_id            = azuread_application.litellm[0].id
    service_principal_id = azuread_service_principal.litellm[0].id
    client_secret        = azuread_application_password.litellm[0].value
  } : null
  sensitive = true
}
