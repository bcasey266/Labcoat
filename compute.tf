resource "azurerm_service_plan" "this" {
  name                = var.ServicePlanName
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  os_type  = "Windows"
  sku_name = "EP1"
}

resource "azurerm_storage_share" "this" {
  name                 = "sandboxmgmt"
  storage_account_name = azurerm_storage_account.this.name
  quota                = 50
}

resource "azurerm_windows_function_app" "this" {
  name                = var.FunctionAppName
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags = {
    "hidden-link: /app-insights-conn-string"         = azurerm_application_insights.this.connection_string
    "hidden-link: /app-insights-instrumentation-key" = azurerm_application_insights.this.instrumentation_key
    "hidden-link: /app-insights-resource-id"         = azurerm_application_insights.this.id
  }

  lifecycle {
    ignore_changes = [
      tags["hidden-link: /app-insights-resource-id"]
    ]
  }

  depends_on = [
    azurerm_private_endpoint.sandboxmgmtstorageblob,
    azurerm_private_endpoint.sandboxmgmtstoragetable,
    azurerm_private_endpoint.sandboxmgmtstoragefile,
    azurerm_private_endpoint.keyvault,
    azurerm_role_assignment.sandboxmgmtSecretReader,
    azurerm_role_assignment.sandboxmgmtBlobContributor,
    azurerm_role_assignment.sandboxmgmtSAContributor,
  ]

  storage_key_vault_secret_id     = azurerm_key_vault_secret.sandboxmgmtstorage.versionless_id
  key_vault_reference_identity_id = azurerm_user_assigned_identity.this.id
  service_plan_id                 = azurerm_service_plan.this.id
  https_only                      = true
  virtual_network_subnet_id       = azurerm_subnet.vnetintegration.id
  zip_deploy_file                 = data.archive_file.function_app_code.output_path

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"                 = "1"
    "WEBSITE_CONTENTSHARE"                     = azurerm_storage_share.this.name
    "WEBSITE_CONTENTOVERVNET"                  = 1
    "WEBSITE_SKIP_CONTENTSHARE_VALIDATION"     = 1
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.sandboxmgmtstorage.versionless_id})"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  site_config {
    ftps_state                             = "Disabled"
    minimum_tls_version                    = "1.2"
    application_insights_connection_string = azurerm_application_insights.this.connection_string
    application_insights_key               = azurerm_application_insights.this.instrumentation_key
    vnet_route_all_enabled                 = true
    scm_use_main_ip_restriction            = true
    application_stack {
      powershell_core_version = "7.2"
    }
    ip_restriction {
      action     = "Allow"
      ip_address = "${chomp(data.http.myip.response_body)}/32"
      name       = "Default Block"
      priority   = 1
    }
  }
}

## Application Code
resource "random_uuid" "AppChange" {
  keepers = {
    for filename in(
      fileset("FunctionCode", "**")
    ) :
    filename => filemd5("FunctionCode/${filename}")
  }
}

data "archive_file" "function_app_code" {
  type        = "zip"
  source_dir  = "FunctionCode"
  output_path = "function-${random_uuid.AppChange.result}.zip"
}
