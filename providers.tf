terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.52.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.37.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "1.5.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {
  tenant_id = var.AzureADTenantID
}

provider "azapi" {
}
