resource "azurerm_service_plan" "appsvc" {
  name                = local.project_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "random_password" "app-key" {
  length  = 64
  special = false
}

resource "azurerm_linux_web_app" "appsvc" {
  name                = local.project_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.appsvc.id
  site_config {
    application_stack {
      docker_image     = var.docker_image
      docker_image_tag = var.docker_image_tag
    }
  }
  logs {
    http_logs {
      file_system {
        retention_in_mb   = 35
        retention_in_days = 0
      }
    }
  }
  app_settings = {
    DOCKER_REGISTRY_SERVER_URL          = "https://index.docker.io/v1"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "true"
    RAILS_IN_SERVICE                    = "false"
    RAILS_ENV                           = "production"
    SECRET_KEY_BASE                     = random_password.app-key.result
    DATABASE_URL                        = "mysql2://${urlencode(local.db_user_name_ext)}:${urlencode(local.db_user_pass)}@${azurerm_mariadb_server.db.fqdn}/${local.db_name}?encoding=utf8mb4&sslverify=true"
    DB_ADMIN_CMD                        = local.db_admin_cmd
    DB_USER_CMD                         = local.db_user_cmd
  }
}

