resource "azurerm_log_analytics_workspace" "logws" {
  name                = local.project_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "logws" {
  name                       = "logws"
  target_resource_id         = azurerm_linux_web_app.appsvc.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logws.id
  log {
    category = "AppServiceConsoleLogs"
    enabled  = true
  }
  log {
    category = "AppServiceHTTPLogs"
    enabled  = true
  }
  log {
    category = "AppServicePlatformLogs"
    enabled  = true
  }
  metric {
    category = "AllMetrics"
    enabled = true
  }
}
