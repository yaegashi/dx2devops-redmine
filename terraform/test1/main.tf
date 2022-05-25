provider "azurerm" {
  features {}
}

locals {
  project_name = "${var.prefix}-${random_id.uniq.hex}"
}

resource "random_id" "uniq" {
  byte_length = 4
}

resource "azurerm_resource_group" "rg" {
  name     = local.project_name
  location = var.location
}
