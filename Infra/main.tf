data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.region
}

resource "azurerm_key_vault" "this" {
  name                       = var.key_vault_name
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
    ip_rules       = tolist(var.ip_allowlist[*].ip)
  }
}

resource "azurerm_storage_account" "this" {
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  name                     = var.storage_account_name
  account_replication_type = "LRS"
  account_tier             = "Standard"
  network_rules {
    default_action = "Deny"
    ip_rules       = tolist(var.ip_allowlist[*].ip)
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
  name                = var.log_analytics_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "this" {
  name                = var.application_insights_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.this.id
}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = "id-${var.function_app_name}"
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
  scope                = "/subscriptions/${var.sandbox_azure_subscription_id}"
  role_definition_name = "Owner"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "azuread_directory_role_assignment" "userread" {
  role_id             = "88d8e3e3-8f55-4a1e-953a-9b9898b8876b"
  principal_object_id = azurerm_user_assigned_identity.this.principal_id
}

module "Networking" {
  count  = var.enable_private_networking == true ? 1 : 0
  source = "./Modules/Networking"

  vnet_name            = var.vnet_name
  region               = var.region
  resource_group_name  = azurerm_resource_group.this.name
  storage_account_name = azurerm_storage_account.this.name
  StorageAccountID     = azurerm_storage_account.this.id
  key_vault_name       = azurerm_key_vault.this.name
  KeyVaultID           = azurerm_key_vault.this.id
}


module "FunctionApp" {
  source = "./Modules/FunctionApp"

  depends_on = [
    module.Networking,
    azurerm_role_assignment.sandboxmgmtSecretReader,
    azurerm_role_assignment.sandboxmgmtBlobContributor,
    azurerm_role_assignment.sandboxmgmtSAContributor,
  ]

  region                        = var.region
  sandbox_azure_subscription_id = var.sandbox_azure_subscription_id
  resource_group_name           = azurerm_resource_group.this.name
  SubnetID                      = var.enable_private_networking == true ? module.Networking[0].VNETIntegrationSubnetID : null
  storage_account_name          = azurerm_storage_account.this.name
  app_service_plan_name         = var.app_service_plan_name
  function_app_name             = var.function_app_name
  keyvaultsecret                = azurerm_key_vault_secret.sandboxmgmtstorage.versionless_id
  useridentity                  = azurerm_user_assigned_identity.this.id
  useridentityclientid          = azurerm_user_assigned_identity.this.client_id
  SandboxManagementSubscription = data.azurerm_client_config.current.subscription_id
  ip_allowlist                  = var.ip_allowlist
  AppInsightsID                 = azurerm_application_insights.this.id
  AppInsightsConnectionString   = azurerm_application_insights.this.connection_string
  AppInsightsInstrumentationKey = azurerm_application_insights.this.instrumentation_key
  StorageQueueNotifications     = module.Notifications.StorageQueueNotifications
  FrontendPortalURL             = module.Frontend.FrontendPortalURL
}

module "Notifications" {
  source = "./Modules/Notifications"

  region                        = var.logic_app_region
  resource_group_name           = azurerm_resource_group.this.name
  ResourceGroupID               = azurerm_resource_group.this.id
  SandboxManagementSubscription = data.azurerm_client_config.current.subscription_id
  logic_app_name                = var.logic_app_name
  FrontendPortalURL             = module.Frontend.FrontendPortalURL
  sandbox_azure_subscription_id = var.sandbox_azure_subscription_id
  storage_account_name          = azurerm_storage_account.this.name
  StorageAccountID              = azurerm_storage_account.this.id
  TenantID                      = var.azuread_tenant_id
}

module "APIM" {
  source = "./Modules/APIM"

  frontend_app_registration_name = var.frontend_app_registration_name
  AppOwnerObjectID               = data.azuread_client_config.current.object_id
  FrontendHostname               = module.Frontend.FrontendHostname
  region                         = var.logic_app_region
  resource_group_name            = azurerm_resource_group.this.name
  api_management_name            = var.api_management_name
  api_management_admin_name      = var.api_management_admin_name
  api_management_admin_email     = var.api_management_admin_email
  function_app_name              = var.function_app_name
  FunctionAppHostName            = module.FunctionApp.FunctionAppHostName
  FunctionAppHostKey             = module.FunctionApp.FunctionAppHostKey
  azuread_tenant_id              = var.azuread_tenant_id
}

module "Frontend" {
  source = "./Modules/Frontend"

  region                         = var.logic_app_region
  resource_group_name            = azurerm_resource_group.this.name
  app_service_plan_frontend_name = var.app_service_plan_frontend_name
  web_app_name                   = var.web_app_name
  FrontendAppID                  = module.APIM.FrontendAppID
  azuread_tenant_id              = var.azuread_tenant_id
  sandbox_azure_subscription_id  = var.sandbox_azure_subscription_id
  APIMGatewayURL                 = module.APIM.APIMGatewayURL
  APIName                        = module.APIM.APIName
  APICreateURL                   = module.APIM.APICreateURL
  APIListURL                     = module.APIM.APIListURL
  APIDeleteURL                   = module.APIM.APIDeleteURL
  APIResetURL                    = module.APIM.APIResetURL
}
