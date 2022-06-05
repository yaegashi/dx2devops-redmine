resource "azurerm_mariadb_server" "db" {
  name                         = local.project_name
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  sku_name                     = "B_Gen5_1"
  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  administrator_login          = local.db_admin_name
  administrator_login_password = local.db_admin_pass
  version                      = "10.3"
  ssl_enforcement_enabled      = true
}

resource "azurerm_mariadb_firewall_rule" "db" {
  name                = "allow-azure"
  resource_group_name = azurerm_mariadb_server.db.resource_group_name
  server_name         = azurerm_mariadb_server.db.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}
