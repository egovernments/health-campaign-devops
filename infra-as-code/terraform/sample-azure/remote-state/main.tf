provider "azurerm" {
  features {}
}

# This configuration is now handled by Azure CLI in the workflow
# The resource group, storage account, and container are created via az CLI commands
# before terraform init is run, using the values from input.yaml

# We just need to output the values for reference
output "resource_group_name" {
  value = var.resource_group
}

output "storage_account_name" {
  value = var.storage_account_name
}

output "container_name" {
  value = var.storage_container_name
}