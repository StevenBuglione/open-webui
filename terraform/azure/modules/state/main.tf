resource "azurerm_resource_group" "state" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "state" {
  name                            = var.storage_account_name
  resource_group_name             = azurerm_resource_group.state.name
  location                        = azurerm_resource_group.state.location
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  account_kind                    = "StorageV2"
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  large_file_share_enabled        = false
  tags                            = var.tags

  blob_properties {
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
  }

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }

  dynamic "identity" {
    for_each = var.customer_managed_identity_id == null ? [] : [var.customer_managed_identity_id]
    content {
      type         = "UserAssigned"
      identity_ids = [identity.value]
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key_id == null ? [] : [var.customer_managed_key_id]
    content {
      key_vault_key_id          = customer_managed_key.value
      user_assigned_identity_id = var.customer_managed_identity_id
    }
  }

  lifecycle {
    precondition {
      condition     = !(var.customer_managed_key_id != null && var.customer_managed_identity_id == null)
      error_message = "customer_managed_identity_id must be provided when customer_managed_key_id is set."
    }
  }
}

resource "azurerm_storage_container" "state" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.state.name
  container_access_type = "private"
}
