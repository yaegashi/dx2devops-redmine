output "rg_name" {
  value = azurerm_resource_group.rg.name
}

output "appsvc_name" {
  value = azurerm_linux_web_app.appsvc.name
}

output "appsvc_id" {
  value = azurerm_linux_web_app.appsvc.id
}

output "db_host" {
  value = local.db_host
}

output "db_name" {
  value = local.db_name
}

output "db_admin_name" {
  value = local.db_admin_name_ext
}

output "db_admin_pass" {
  value     = local.db_admin_pass
  sensitive = true
}

output "db_admin_cmd" {
  value = local.db_admin_cmd
}

output "db_user_name" {
  value = local.db_user_name_ext
}

output "db_user_pass" {
  value     = local.db_user_pass
  sensitive = true
}

output "db_user_cmd" {
  value = local.db_user_cmd
}
