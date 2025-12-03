resource "azuread_synchronization_secret" "scim" {
  count                = var.enabled ? 1 : 0
  service_principal_id = var.service_principal_id

  credential {
    key   = "BaseAddress"
    value = var.base_address
  }

  credential {
    key   = "SecretToken"
    value = var.secret_token
  }
}

resource "azuread_synchronization_job" "scim" {
  count                = var.enabled ? 1 : 0
  service_principal_id = var.service_principal_id
  template_id          = var.template_id
  enabled              = true

  depends_on = [azuread_synchronization_secret.scim]
}
