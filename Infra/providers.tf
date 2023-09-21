terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.73.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.42.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "1.8.0"
    }
  }
  backend "azurerm" {
  }
}

provider "azurerm" {
  features {
    key_vault {
      recover_soft_deleted_secrets = true
    }
  }
}

provider "azuread" {
  tenant_id = var.azuread_tenant_id
}

provider "azapi" {
}

