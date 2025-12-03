resource "azurerm_log_analytics_workspace" "this" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_in_days
  daily_quota_gb      = -1
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each                   = { for source in var.diagnostic_sources : source.name => source }
  name                       = each.key
  target_resource_id         = each.value.resource_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  dynamic "enabled_log" {
    for_each = length(each.value.log_categories) == 0 ? [] : each.value.log_categories
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = length(each.value.metric_categories) == 0 ? [] : each.value.metric_categories
    content {
      category = metric.value
    }
  }
}
