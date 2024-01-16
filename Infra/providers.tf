provider "azurerm" {
  features {
    key_vault {
      recover_soft_deleted_secrets = true
    }
  }
  storage_use_azuread = true
}

provider "azuread" {
  tenant_id = var.azuread_tenant_id
}

provider "azapi" {
}

