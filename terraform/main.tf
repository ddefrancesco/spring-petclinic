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

resource "azurerm_app_service_plan" "pc_app_svc_plan" {
  name                = "tmp-pc-appserviceplan"
  location            = azurerm_resource_group.pc_res_group.location
  resource_group_name = azurerm_resource_group.pc_res_group.name
  kind = "Linux"
  reserved = "true"

  sku {
    tier              = "PremiumV2"
    size              = "P1v2"
  }
}

resource "azurerm_app_service" "pc_app_svc" {
  name = "tmp-pc-app-service"
  location = azurerm_resource_group.pc_res_group.location
  resource_group_name = azurerm_resource_group.pc_res_group.name
  app_service_plan_id = azurerm_app_service_plan.pc_app_svc_plan.id

  https_only          = true
  site_config {
    linux_fx_version  = "JAVA|11-java11"
  }

  app_settings = {
    "SPRING_PROFILES_ACTIVE" = "mysql"
    "SPRING_DATASOURCE_URL" = "jdbc:mysql://${azurerm_mysql_server.pc_mysql_rg.fqdn}:3306/${azurerm_mysql_database.pc_mysql_database.name}?useUnicode=true&characterEncoding=utf8&useSSL=true&useLegacyDatetimeCode=false&serverTimezone=UTC"
    "SPRING_DATASOURCE_USERNAME" = "${azurerm_mysql_server.pc_mysql_rg.administrator_login}@${azurerm_mysql_server.pc_mysql_rg.name}"
    "SPRING_DATASOURCE_PASSWORD" = azurerm_mysql_server.pc_mysql_rg.administrator_login_password
  }

}

