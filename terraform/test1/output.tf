output "rg_name" {
  value = azurerm_resource_group.rg.name
}

output "appsvc_name" {
  value = azurerm_linux_web_app.appsvc.name
}

output "appsvc_id" {
  value = azurerm_linux_web_app.appsvc.id
}
