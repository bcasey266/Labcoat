terraform {
  required_version = ">= 1.4.0, <= 1.5.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.80.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.45.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "1.12.1"
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

