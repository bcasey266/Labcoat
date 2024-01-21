provider "azurerm" {
  features {
    application_insights {
      disable_generated_rule = false
    }
    key_vault {
      recover_soft_deleted_secrets = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  storage_use_azuread = true
}

provider "azuread" {
  tenant_id = var.azuread_tenant_id
}

provider "azapi" {
}

