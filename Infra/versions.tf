terraform {
  required_version = ">= 1.4.0, <= 1.5.5"

  #backend "azurerm" {
  #}

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
      version = "1.9.0"
    }
  }
}