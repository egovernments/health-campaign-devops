provider "azurerm" {
  features {}
  subscription_id                 = "777e3e4b-0998-4759-adc2-e7b5b19a6b28"
  resource_provider_registrations = "none"

  # Service Principal authentication (uses environment variables if not specified)
  # ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.64"
    }
  }

  # State lives in the existing tfstate account alongside hcm-demo, in its own
  # container so the two environments can never clobber each other's state.
  backend "azurerm" {
    resource_group_name  = "hcm-demo-rg"
    storage_account_name = "tfstate6fryx"
    container_name       = "hcm-demo-v2-container"
    key                  = "terraform.tfstate"
  }
}
