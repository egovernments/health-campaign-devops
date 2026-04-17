resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group}"
  dns_prefix          = "afrohcm-t--AFROHCM-T-EUW-RG-8c247e"

  
  default_node_pool {
    name       = "nodepool1"
    node_count = "${var.node_count}"
    max_pods   = "100"
    vm_size    = "${var.vm_size}"
    vnet_subnet_id = "${var.vnet_subnet_id}"
    node_public_ip_enabled = false
    os_disk_size_gb = var.os_disk_size_gb
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
    network_plugin_mode = "overlay"  # Enable CNI Overlay mode
    outbound_type       = "userAssignedNATGateway" # Use NAT Gateway
    dns_service_ip      = "172.17.0.10"  # Changed to avoid conflicts
    service_cidr        = "172.17.0.0/16" # Changed from 10.2.0.0/16
    pod_cidr            = "192.168.0.0/16" # Pod CIDR for overlay mode
  }

  # oms_agent {
  #   log_analytics_workspace_id      = azurerm_log_analytics_workspace.logs_workspace.id
  # }

  tags = {
    Environment = "${var.environment}"
    ManagedBy = "Terraform"
    Project = "AFROHCM"
    "appcode"     = "AFROHCM"
  }

}

# resource "azurerm_log_analytics_workspace" "logs_workspace" {
#   name                = "${var.name}-logs-workspace"
#   location            = "${var.location}"
#   resource_group_name = "${var.resource_group}"

#   sku                 = "PerGB2018"
#   retention_in_days   = 30

# }
