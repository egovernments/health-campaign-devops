resource "azurerm_postgresql_flexible_server" "postgresql_server" {
  name                = "${var.environment}-server"
  location             = "${var.location}"
  resource_group_name  = "${var.resource_group}"

  administrator_login              = "${var.administrator_login}"
  administrator_password     = "${var.administrator_password}"

  sku_name                         = "${var.sku_name}"
  version                          = "${var.db_version}"
  storage_mb                       = "${var.storage_mb}"
  zone = 3

  backup_retention_days            = "${var.backup_retention_days}"
  geo_redundant_backup_enabled     = false
  public_network_access_enabled    = false

  delegated_subnet_id       = "${var.delegated_subnet_id}"
  private_dns_zone_id       = "${var.private_dns_zone_id}"

  tags = {
    environment = "${var.environment}"
  }

}

resource "azurerm_postgresql_flexible_server_database" "db" {
  name                = "${var.environment}-db"
  server_id           = azurerm_postgresql_flexible_server.postgresql_server.id
  charset             = "UTF8"
  collation           = "en_US.utf8"
  lifecycle {
    prevent_destroy = false
  }
}

resource "azurerm_postgresql_flexible_server_configuration" "log_checkpoints" {
  name      = "log_checkpoints"
  server_id = azurerm_postgresql_flexible_server.postgresql_server.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_connections" {
  name      = "log_connections"
  server_id = azurerm_postgresql_flexible_server.postgresql_server.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "require_secure_transport" {
  name      = "require_secure_transport"
  server_id = azurerm_postgresql_flexible_server.postgresql_server.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "ssl_min_protocol_version" {
  name      = "ssl_min_protocol_version"
  server_id = azurerm_postgresql_flexible_server.postgresql_server.id
  value     = "TLSv1.2"
}
