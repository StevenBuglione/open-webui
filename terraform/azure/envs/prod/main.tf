locals {
  environment = "prod"
  base_tags = merge(var.tags, {
    Environment = local.environment
    Application = "OpenWebUI"
  })

  openid_app_config = {
    display_name            = "OpenWebUI (${local.environment})"
    redirect_uris           = var.openwebui_redirect_uris
    logout_url              = var.openwebui_logout_url
    identifier_uris         = length(var.openwebui_identifier_uris) > 0 ? var.openwebui_identifier_uris : null
    group_membership_claims = ["SecurityGroup"]
    sign_in_audience        = "AzureADMyOrg"
    app_roles               = var.openwebui_app_roles
  }

  scim_app_config = {
    enabled          = var.scim_enabled
    display_name     = "OpenWebUI SCIM (${local.environment})"
    identifier_uris  = null
    sign_in_audience = "AzureADMyOrg"
  }

  lite_llm_app_config = {
    enabled          = var.lite_llm_application_enabled
    display_name     = var.lite_llm_display_name
    identifier_uris  = length(var.lite_llm_identifier_uris) > 0 ? var.lite_llm_identifier_uris : null
    sign_in_audience = "AzureADMyOrg"
  }
}

resource "azurerm_resource_group" "security" {
  name     = var.security_resource_group_name
  location = var.location
  tags     = local.base_tags
}

resource "azurerm_resource_group" "monitoring" {
  name     = var.monitoring_resource_group_name
  location = var.location
  tags     = local.base_tags
}

module "identity" {
  source = "../../modules/identity"

  create_administrative_unit       = var.create_administrative_unit
  administrative_unit_display_name = var.administrative_unit_display_name
  role_assignments                 = var.role_assignments
}

module "groups" {
  source = "../../modules/groups"

  administrative_unit_id = module.identity.administrative_unit_id
  groups                 = var.groups
}

module "rbac_mapping" {
  source = "../../modules/rbac_mapping"

  group_lookup = module.groups.groups
  mappings     = var.rbac_mappings
}

module "app_registrations" {
  source = "../../modules/app_registrations"

  tenant_id            = var.tenant_id
  openid_application   = local.openid_app_config
  scim_application     = local.scim_app_config
  lite_llm_application = local.lite_llm_app_config
}

module "monitoring" {
  source = "../../modules/monitoring"

  resource_group_name = azurerm_resource_group.monitoring.name
  location            = azurerm_resource_group.monitoring.location
  workspace_name      = var.log_analytics_workspace_name
  diagnostic_sources  = var.diagnostic_sources
  retention_in_days   = 365
}

locals {
  key_vault_secrets = merge(
    {
      "openid-client-secret" = {
        value = module.app_registrations.openid.client_secret
      }
    },
    var.scim_enabled && module.app_registrations.scim != null ? {
      "scim-provisioning-token" = {
        value = module.app_registrations.scim.client_secret
      }
    } : {},
    var.lite_llm_application_enabled && module.app_registrations.litellm != null ? {
      "litellm-client-secret" = {
        value = module.app_registrations.litellm.client_secret
      }
    } : {}
  )
}

module "secrets" {
  source = "../../modules/secrets"

  resource_group_name        = azurerm_resource_group.security.name
  location                   = azurerm_resource_group.security.location
  key_vault_name             = var.key_vault_name
  tenant_id                  = var.tenant_id
  log_analytics_workspace_id = null
  tags                       = local.base_tags
  private_endpoint_subnet_id = var.key_vault_private_endpoint_subnet_id
  virtual_network_id         = var.virtual_network_id
  secrets                    = local.key_vault_secrets
  secret_names               = keys(nonsensitive(local.key_vault_secrets))
  rbac_assignments           = var.key_vault_rbac_assignments
}

module "scim" {
  count  = var.scim_enabled ? 1 : 0
  source = "../../modules/scim"

  enabled              = var.scim_enabled
  service_principal_id = try(module.app_registrations.scim.service_principal_id, null)
  base_address         = var.scim_base_address
  secret_token         = var.scim_secret_token
  template_id          = var.scim_template_id
}

locals {
  application_aliases = {
    OPENWEBUI = module.app_registrations.openid.client_id
    LITELLM   = module.app_registrations.litellm != null ? module.app_registrations.litellm.client_id : null
  }

  conditional_policies = [
    for policy in var.conditional_access_policies : merge(policy, {
      include_applications = [
        for app in policy.include_applications :
        coalesce(lookup(local.application_aliases, upper(app), null), app)
      ]
    })
  ]
}

module "conditional_access" {
  count    = length(local.conditional_policies) > 0 ? 1 : 0
  source   = "../../modules/conditional_access"
  policies = local.conditional_policies
}
