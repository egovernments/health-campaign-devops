provider "azurerm" {
  features {}
  subscription_id = "8c247e8d-4f67-46e2-b10e-e89fc1a60fbd"
  resource_provider_registrations = "none"

  # Service Principal authentication (uses environment variables if not specified)
  # ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
}

terraform {
  backend "azurerm" {
    resource_group_name  = "AFROHCM-T-EUW-RG01"
    storage_account_name = "afrohcmteuwstg"
    container_name       = "afrohcm-t-euw-container"
    key                  = "terraform.tfstate"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-afrohcm-t-01"  # Following naming convention
  address_space       = ["10.20.27.0/24"]    # New allocated range
  location            = var.location
  resource_group_name = var.resource_group
}

resource "azurerm_subnet" "aks" {
  name         = "snet-aks-afrohcm-t-01"  # Following naming convention
  resource_group_name = var.resource_group
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes   = ["10.20.27.0/25"]  # 128 IPs for AKS
}

# Give AKS system-assigned identity permission to join the subnet
# This will be created by the service principal with User Access Administrator role
# resource "azurerm_role_assignment" "aks_subnet_network_contributor" {
#   principal_id         = module.kubernetes.aks_principal_id
#   role_definition_name = "Network Contributor"
#   scope                = azurerm_subnet.aks.id

#   depends_on = [module.kubernetes]
# }

resource "azurerm_subnet" "postgres" {
  name         = "snet-postgres-afrohcm-t-01"  # Following naming convention
  resource_group_name = var.resource_group
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes   = ["10.20.27.128/26"]  # 64 IPs for PostgreSQL
  service_endpoints  = ["Microsoft.Storage"]

  delegation {
    name = "fs"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# Create Public IP for Internet Gateway
resource "azurerm_public_ip" "public_ip" {
  name                = "${var.environment}-public-ip"
  resource_group_name = var.resource_group
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create NAT Gateway (optional, for private subnet internet access)
resource "azurerm_nat_gateway" "nat" {
  name                = "${var.environment}-nat-gateway"
  location            = var.location
  resource_group_name = var.resource_group
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.public_ip.id
}

# Associate NAT with private subnet (to give it outbound access)
resource "azurerm_subnet_nat_gateway_association" "nat_private" {
  subnet_id      = azurerm_subnet.aks.id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "db_net_link" {
  name                  = "${var.environment}VnetZone.com"
  private_dns_zone_name = azurerm_private_dns_zone.db.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  resource_group_name   = var.resource_group
}

resource "azurerm_private_dns_zone" "db" {
  name                = "${var.environment}.postgres.database.azure.com"
  resource_group_name = var.resource_group
}

module "kubernetes" {
  depends_on = [azurerm_nat_gateway_public_ip_association.nat_assoc]
  source                    = "../modules/kubernetes/azure"
  environment               = var.environment
  name                      = var.environment
  location                  = var.location
  resource_group            = var.resource_group
  vm_size                   = "Standard_E2as_v5"
  node_count                = 4
  vnet_subnet_id            = azurerm_subnet.aks.id
  os_disk_size_gb           = 64
}

module "postgres-db" {
  source                    = "../modules/db/azure"
  environment               = var.environment
  resource_group            = var.resource_group
  location                  = var.location
  sku_name                  = "B_Standard_B2ms"
  storage_mb                = "65536"
  backup_retention_days     = "7"
  administrator_login       = var.db_user
  administrator_password    = var.db_password
  db_version                = var.db_version
  delegated_subnet_id       = azurerm_subnet.postgres.id
  private_dns_zone_id       = azurerm_private_dns_zone.db.id
}