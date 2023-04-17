resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = "id-${var.FunctionAppName}"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_role_assignment" "sandboxmgmtBlobContributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "azurerm_role_assignment" "sandboxmgmtSAContributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "azurerm_role_assignment" "sandboxmgmtTableContributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "azurerm_role_assignment" "sandboxmgmtQueueContributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "azurerm_role_assignment" "sandboxmgmtSecretReader" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "azurerm_role_assignment" "sandboxmgmtSandboxMG" {
  scope                = "/subscriptions/${var.SandboxSubID}"
  role_definition_name = "Owner"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "azuread_directory_role_assignment" "userread" {
  role_id             = "88d8e3e3-8f55-4a1e-953a-9b9898b8876b"
  principal_object_id = azurerm_user_assigned_identity.this.principal_id
}
