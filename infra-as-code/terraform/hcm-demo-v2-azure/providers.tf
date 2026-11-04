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

  # State lives in this environment's own resource group. It was originally in
  # hcm-demo-rg's tfstate account, which would have orphaned the state for the
  # environment being kept once the old resource group is deleted.
  backend "azurerm" {
    resource_group_name  = "hcm-demo-v2-rg"
    storage_account_name = "tfstatehcmdemov248f9cb"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
