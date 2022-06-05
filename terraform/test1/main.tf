provider "azurerm" {
  features {}
}

locals {
  project_name      = "${var.prefix}-${random_id.uniq.hex}"
  db_name           = replace(local.project_name, "-", "_")
  db_host           = azurerm_mariadb_server.db.fqdn
  db_user_name      = local.db_name
  db_user_name_ext  = "${local.db_user_name}@${azurerm_mariadb_server.db.name}"
  db_user_pass      = random_password.user.result
  db_user_cmd       = "mysql --ssl -vv -p -u ${local.db_user_name_ext} -h ${local.db_host}"
  db_admin_name     = "db_admin"
  db_admin_name_ext = "${local.db_admin_name}@${azurerm_mariadb_server.db.name}"
  db_admin_pass     = random_password.admin.result
  db_admin_cmd      = "mysql --ssl -vv -p -u ${local.db_admin_name_ext} -h ${local.db_host}"
}

resource "random_id" "uniq" {
  byte_length = 4
}

resource "random_password" "user" {
  length = 32
}

resource "random_password" "admin" {
  length = 32
}

resource "azurerm_resource_group" "rg" {
  name     = local.project_name
  location = var.location
}
