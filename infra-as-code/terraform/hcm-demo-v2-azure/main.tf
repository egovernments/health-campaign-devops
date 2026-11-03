# Parallel HCM demo environment for the v2.2 release, in Azure Central India.
#
# Mirrors the live hcm-demo environment (Central US) as the restore target for a
# snapshot of its data. Resources are declared here rather than through
# ../modules/* because this environment needs a node-pool autoscaler, its own
# dns_prefix and an application database named to match the source — none of
# which the shared modules expose, and changing them would touch other
# environments that depend on their current behaviour.

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "HCM"
    Purpose     = "hcm-v2.2-parallel-demo"
  }
}

### Network >>>>>>>>>>>>>>>>>>>>

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.environment}-01"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks-${var.environment}-01"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.aks_subnet_cidr]
}

resource "azurerm_subnet" "postgres" {
  name                 = "snet-postgres-${var.environment}-01"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.postgres_subnet_cidr]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "fs"

    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.environment}-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat" {
  name                = "${var.environment}-nat-gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.public_ip.id
}

resource "azurerm_subnet_nat_gateway_association" "nat_aks" {
  subnet_id      = azurerm_subnet.aks.id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}

### PostgreSQL private DNS >>>>>>>>>>>>>>>>>>>>

resource "azurerm_private_dns_zone" "db" {
  name                = "${var.environment}-server.private.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "db_net_link" {
  name                  = "vnet-${var.environment}-01-link"
  private_dns_zone_name = azurerm_private_dns_zone.db.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  resource_group_name   = azurerm_resource_group.rg.name
}

### AKS >>>>>>>>>>>>>>>>>>>>

resource "azurerm_kubernetes_cluster" "aks" {
  depends_on = [azurerm_nat_gateway_public_ip_association.nat_assoc]

  name                = var.environment
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.environment
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                   = "nodepool1"
    node_count             = var.node_count
    min_count              = var.node_min_count
    max_count              = var.node_max_count
    auto_scaling_enabled   = true
    max_pods               = 100
    vm_size                = var.vm_size
    vnet_subnet_id         = azurerm_subnet.aks.id
    node_public_ip_enabled = false
    os_disk_size_gb        = var.os_disk_size_gb

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    outbound_type       = "userAssignedNATGateway"
    dns_service_ip      = "172.17.0.10"
    service_cidr        = "172.17.0.0/16"
    pod_cidr            = "192.168.0.0/16"
  }

  lifecycle {
    # The autoscaler owns node_count once the cluster is live.
    ignore_changes = [default_node_pool[0].node_count]
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "HCM"
    appcode     = "HCM"
  }
}

### PostgreSQL flexible server >>>>>>>>>>>>>>>>>>>>

resource "azurerm_postgresql_flexible_server" "postgresql_server" {
  name                = "${var.environment}-server"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  administrator_login    = var.db_user
  administrator_password = var.db_password

  sku_name   = var.db_sku_name
  version    = var.db_version
  storage_mb = var.db_storage_mb

  backup_retention_days         = var.db_backup_retention_days
  geo_redundant_backup_enabled  = false
  public_network_access_enabled = false

  delegated_subnet_id = azurerm_subnet.postgres.id
  private_dns_zone_id = azurerm_private_dns_zone.db.id

  depends_on = [azurerm_private_dns_zone_virtual_network_link.db_net_link]

  lifecycle {
    # Azure picks the availability zone at create time; leaving it unset here
    # otherwise shows as a permanent diff trying to unset it on every plan.
    ignore_changes = [zone]
  }

  tags = {
    environment = var.environment
  }
}

resource "azurerm_postgresql_flexible_server_database" "db" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.postgresql_server.id
  charset   = "UTF8"
  collation = "en_US.utf8"

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

### Filestore storage account >>>>>>>>>>>>>>>>>>>>

resource "azurerm_storage_account" "filestore" {
  name                     = var.filestore_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  tags = {
    environment = var.environment
  }
}

resource "azurerm_storage_container" "filestore" {
  for_each = toset(var.filestore_containers)

  name                  = each.value
  storage_account_id    = azurerm_storage_account.filestore.id
  container_access_type = "private"
}

### Key Vault >>>>>>>>>>>>>>>>>>>>

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                       = "${var.environment}-kv"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  tags = {
    environment = var.environment
  }
}

### Static Elasticsearch disks >>>>>>>>>>>>>>>>>>>>
# hcm-demo binds Elasticsearch to pre-created managed disks through static PVs
# with a Retain policy, so index data survives the StatefulSet. The same disks
# are created here; the matching PVs are applied from the restore runbook.

resource "azurerm_managed_disk" "es_data" {
  count = var.es_node_count

  name                 = "es-data-disk-${count.index}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.es_data_disk_size_gb

  tags = {
    environment = var.environment
  }
}

resource "azurerm_managed_disk" "es_master" {
  count = var.es_node_count

  name                 = "es-master-disk-${count.index}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.es_master_disk_size_gb

  tags = {
    environment = var.environment
  }
}

### AKS access to the ES disks and filestore >>>>>>>>>>>>>>>>>>>>
# The kubelet identity attaches the static disks; without this the ES pods stay
# in ContainerCreating with an authorization error on the disk URI.

resource "azurerm_role_assignment" "aks_disk_contributor" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}
