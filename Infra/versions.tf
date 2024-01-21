terraform {
  required_version = ">= 1.5.5, <= 2.0.0"

  backend "azurerm" {
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.87.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.47.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "1.10.0"
    }
  }
}
