provider "azurerm" {
  features {}
  version = "=2.20.0"
}

resource "azurerm_resource_group" "pc_res_group" {
  location = var.location
  name = "tmp-petclinic"

  tags = {
    "Terraform" = "true"
  }
}

resource "azurerm_mysql_server" "pc_mysql_rg" {
  name                         = "tmp-pc-mysqlserver"
  location                     = azurerm_resource_group.pc_res_group.location
  resource_group_name          = azurerm_resource_group.pc_res_group.name

  administrator_login          = "petclinic"
  administrator_login_password = "p3tcl1n!c"

  sku_name                     = "B_Gen5_1"
  storage_mb                   = 5120
  version                      = "5.7"

  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"
}

resource "azurerm_mysql_database" "pc_mysql_database" {
  name                         = "petclinic"
  resource_group_name          = azurerm_resource_group.pc_res_group.name
  server_name                  = azurerm_mysql_server.pc_mysql_rg.name
  charset                      = "utf8"
  collation                    = "utf8_unicode_ci"
}

resource "azurerm_mysql_firewall_rule" "pc_mysql_fw" {
  name                         = "azure"
  resource_group_name          = azurerm_resource_group.pc_res_group.name
  server_name                  = azurerm_mysql_server.pc_mysql_rg.name
  start_ip_address             = "0.0.0.0"
  end_ip_address               = "0.0.0.0"
}


