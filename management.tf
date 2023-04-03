data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

data "azurerm_client_config" "current" {
}

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
  purge_protection_enabled   = true
  sku_name                   = "standard"
  enable_rbac_authorization  = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = [chomp(data.http.myip.response_body)]
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
    ip_rules       = [chomp(data.http.myip.response_body)]
    bypass         = ["Logging", "Metrics", "AzureServices"]
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
