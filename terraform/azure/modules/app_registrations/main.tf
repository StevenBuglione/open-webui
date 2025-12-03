locals {
  graph_app_id                         = "00000003-0000-0000-c000-000000000000"
  group_member_read_all_application_id = "5b567255-7703-4780-807c-7be8301ae99b"
  group_member_read_all_delegated_id   = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"
  password_rotation_duration           = format("%dh", var.password_rotation_days * 24)
  app_role_uuid_namespace              = "8ab12226-3f0b-4f9f-8a38-1b546672b567"
}

resource "time_static" "password_epoch" {}

resource "azuread_application" "openid" {
  display_name            = var.openid_application.display_name
  sign_in_audience        = var.openid_application.sign_in_audience
  group_membership_claims = var.openid_application.group_membership_claims
  identifier_uris         = try(var.openid_application.identifier_uris, null)

  web {
    redirect_uris = var.openid_application.redirect_uris
    logout_url    = try(var.openid_application.logout_url, null)
    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }

  required_resource_access {
    resource_app_id = local.graph_app_id

    resource_access {
      id   = local.group_member_read_all_application_id
      type = "Role"
    }

    resource_access {
      id   = local.group_member_read_all_delegated_id
      type = "Scope"
    }
  }

  dynamic "app_role" {
    for_each = try(var.openid_application.app_roles, [])
    content {
      allowed_member_types = app_role.value.allowed_member_types
      description          = app_role.value.description
      display_name         = app_role.value.display_name
      enabled              = try(app_role.value.enabled, true)
      value                = app_role.value.value
      id                   = coalesce(try(app_role.value.id, null), uuidv5(local.app_role_uuid_namespace, app_role.value.value))
    }
  }
}

resource "azuread_service_principal" "openid" {
  client_id = azuread_application.openid.client_id
}

resource "azuread_application_password" "openid" {
  application_id = azuread_application.openid.id
  display_name   = "automation"
  end_date       = timeadd(time_static.password_epoch.rfc3339, local.password_rotation_duration)
}

resource "azuread_application" "scim" {
  count            = var.scim_application.enabled ? 1 : 0
  display_name     = var.scim_application.display_name
  sign_in_audience = var.scim_application.sign_in_audience
  identifier_uris  = try(var.scim_application.identifier_uris, null)
  owners           = []
}

resource "azuread_service_principal" "scim" {
  count     = var.scim_application.enabled ? 1 : 0
  client_id = azuread_application.scim[0].client_id
}

resource "azuread_application_password" "scim" {
  count          = var.scim_application.enabled ? 1 : 0
  application_id = azuread_application.scim[0].id
  display_name   = "scim-token"
  end_date       = timeadd(time_static.password_epoch.rfc3339, local.password_rotation_duration)
}

resource "azuread_application" "litellm" {
  count            = var.lite_llm_application.enabled ? 1 : 0
  display_name     = var.lite_llm_application.display_name
  sign_in_audience = var.lite_llm_application.sign_in_audience
  identifier_uris  = try(var.lite_llm_application.identifier_uris, null)
}

resource "azuread_service_principal" "litellm" {
  count     = var.lite_llm_application.enabled ? 1 : 0
  client_id = azuread_application.litellm[0].client_id
}

resource "azuread_application_password" "litellm" {
  count          = var.lite_llm_application.enabled ? 1 : 0
  application_id = azuread_application.litellm[0].id
  display_name   = "automation"
  end_date       = timeadd(time_static.password_epoch.rfc3339, local.password_rotation_duration)
}
