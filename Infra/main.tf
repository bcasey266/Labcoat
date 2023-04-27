data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  name     = var.ResourceGroupName
  location = var.location
}

resource "azurerm_key_vault" "this" {
  name                       = var.KeyVaultName
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  sku_name                   = "standard"
  enable_rbac_authorization  = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = var.AdminIPs
  }
}

resource "azurerm_storage_account" "this" {
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  name                     = var.StorageAccountName
  account_replication_type = "LRS"
  account_tier             = "Standard"
  network_rules {
    default_action = "Deny"
    ip_rules       = var.AdminIPs
    bypass         = ["Logging", "Metrics", "AzureServices"]
    private_link_access {
      endpoint_resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourcegroups/${azurerm_resource_group.this.name}/providers/Microsoft.Logic/workflows/*"
      endpoint_tenant_id   = data.azurerm_client_config.current.tenant_id
    }
  }

  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
}

resource "azurerm_key_vault_secret" "sandboxmgmtstorage" {
  name         = "storageconnectionstring"
  value        = azurerm_storage_account.this.primary_connection_string
  key_vault_id = azurerm_key_vault.this.id
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = var.LogAnalyticsName
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "this" {
  name                = var.ApplicationInsightsName
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.this.id
}

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

module "Networking" {
  count  = var.PrivateNetworking == true ? 1 : 0
  source = "./Modules/Networking"

  VNETName           = var.VNETName
  location           = var.location
  ResourceGroupName  = azurerm_resource_group.this.name
  StorageAccountName = azurerm_storage_account.this.name
  StorageAccountID   = azurerm_storage_account.this.id
  KeyVaultName       = azurerm_key_vault.this.name
  KeyVaultID         = azurerm_key_vault.this.id
}


module "FunctionApp" {
  source = "./Modules/FunctionApp"

  location                      = var.location
  SandboxSubID                  = var.SandboxSubID
  ResourceGroupName             = azurerm_resource_group.this.name
  SubnetID                      = var.PrivateNetworking == true ? module.Networking[0].VNETIntegrationSubnetID : null
  StorageAccountName            = var.StorageAccountName
  ServicePlanName               = var.ServicePlanName
  FunctionAppName               = var.FunctionAppName
  keyvaultsecret                = azurerm_key_vault_secret.sandboxmgmtstorage.versionless_id
  useridentity                  = azurerm_user_assigned_identity.this.id
  useridentityclientid          = azurerm_user_assigned_identity.this.client_id
  SandboxManagementSubscription = data.azurerm_client_config.current.subscription_id
}

module "Notifications" {
  source = "./Modules/Notifications"

  location                      = var.LogicAppLocation
  ResourceGroupName             = azurerm_resource_group.this.name
  ResourceGroupID               = azurerm_resource_group.this.id
  SandboxManagementSubscription = data.azurerm_client_config.current.subscription_id
  LogicAppName                  = var.LogicAppName
  FrontendPortalURL             = "" //azurerm_windows_web_app.this.default_hostname
  SandboxSubID                  = var.SandboxSubID
  StorageAccountName            = var.StorageAccountName
  StorageAccountID              = azurerm_storage_account.this.id
  TenantID                      = var.AzureADTenantID
}
