locals {
  private_endpoint_enabled = var.private_endpoint_subnet_id != null
  dns_zone_required        = local.private_endpoint_enabled && var.create_private_dns_zone && var.existing_private_dns_zone_id == null
}

resource "azurerm_key_vault" "this" {
  name                          = var.key_vault_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = var.tenant_id
  sku_name                      = upper(var.sku_name) == "PREMIUM" ? "premium" : "standard"
  enable_rbac_authorization     = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 90
  public_network_access_enabled = !local.private_endpoint_enabled
  tags                          = var.tags
}

data "azurerm_client_config" "current" {}

resource "azurerm_monitor_diagnostic_setting" "kv" {
  count                      = var.log_analytics_workspace_id == null ? 0 : 1
  name                       = "kv-diagnostics"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_private_dns_zone" "kv" {
  count               = local.dns_zone_required ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv" {
  count                 = local.dns_zone_required && var.virtual_network_id != null ? 1 : 0
  name                  = "kv-${replace(var.key_vault_name, "_", "-")}"
  resource_group_name   = azurerm_private_dns_zone.kv[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.kv[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
}

resource "azurerm_private_endpoint" "kv" {
  count               = local.private_endpoint_enabled ? 1 : 0
  name                = "pe-${var.key_vault_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "kv-pe"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = local.private_endpoint_enabled ? [1] : []
    content {
      name = "kv-dns"
      private_dns_zone_ids = compact([
        var.existing_private_dns_zone_id,
        try(azurerm_private_dns_zone.kv[0].id, null)
      ])
    }
  }
}

locals {
  role_assignments = [
    for assignment in var.rbac_assignments : {
      principal_id       = assignment.principal_id
      role_definition_id = assignment.role_definition_id != null ? assignment.role_definition_id : data.azurerm_role_definition.this[assignment.role_definition_name].id
    }
  ]

  role_definition_names = toset([for assignment in var.rbac_assignments : assignment.role_definition_name])
}

data "azurerm_role_definition" "this" {
  for_each = { for name in local.role_definition_names : name => name }
  name     = each.key
  scope    = azurerm_key_vault.this.id
}

resource "azurerm_role_assignment" "kv" {
  for_each                         = { for idx, assignment in local.role_assignments : idx => assignment }
  scope                            = azurerm_key_vault.this.id
  role_definition_id               = each.value.role_definition_id
  principal_id                     = each.value.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_key_vault_secret" "this" {
  for_each     = toset(var.secret_names)
  name         = each.key
  value        = var.secrets[each.key].value
  content_type = try(var.secrets[each.key].content_type, null)
  key_vault_id = azurerm_key_vault.this.id
}
