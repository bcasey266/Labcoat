resource "azurerm_service_plan" "this" {
  name                = var.app_service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.region

  os_type  = "Windows"
  sku_name = "EP1"
}

resource "azurerm_storage_share" "this" {
  name                 = var.function_app_name
  storage_account_name = var.storage_account_name
  quota                = 50
}

resource "azurerm_storage_queue" "newsandbox" {
  name                 = "newsandbox"
  storage_account_name = var.storage_account_name
}

resource "azurerm_storage_queue" "deletesandbox" {
  name                 = "deletesandbox"
  storage_account_name = var.storage_account_name
}

resource "azurerm_storage_queue" "resetsandbox" {
  name                 = "resetsandbox"
  storage_account_name = var.storage_account_name
}

resource "azurerm_storage_table" "sandboxtable" {
  name                 = "sandboxtable"
  storage_account_name = var.storage_account_name
}

resource "azurerm_windows_function_app" "this" {
  name                = var.function_app_name
  resource_group_name = var.resource_group_name
  location            = var.region
  tags = {
    "hidden-link: /app-insights-conn-string"         = var.AppInsightsConnectionString
    "hidden-link: /app-insights-instrumentation-key" = var.AppInsightsInstrumentationKey
    "hidden-link: /app-insights-resource-id"         = var.AppInsightsID
  }

  lifecycle {
    ignore_changes = [
      tags["hidden-link: /app-insights-resource-id"]
    ]
  }

  storage_key_vault_secret_id     = var.keyvaultsecret
  key_vault_reference_identity_id = var.useridentity
  service_plan_id                 = azurerm_service_plan.this.id
  https_only                      = true
  virtual_network_subnet_id       = var.SubnetID

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"                 = "1"
    "WEBSITE_CONTENTSHARE"                     = azurerm_storage_share.this.name
    "WEBSITE_CONTENTOVERVNET"                  = 1
    "WEBSITE_SKIP_CONTENTSHARE_VALIDATION"     = 1
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = "@Microsoft.KeyVault(SecretUri=${var.keyvaultsecret})"
    "resource_group_name"                      = var.resource_group_name
    "storage_account_name"                     = var.storage_account_name
    "StorageQueueNewSandbox"                   = azurerm_storage_queue.newsandbox.name
    "StorageQueueDeleteSandbox"                = azurerm_storage_queue.deletesandbox.name
    "StorageQueueResetSandbox"                 = azurerm_storage_queue.resetsandbox.name
    "StorageQueueNotifications"                = var.StorageQueueNotifications
    "StorageTableSandbox"                      = azurerm_storage_table.sandboxtable.name
    "SandboxManagementSubscription"            = var.SandboxManagementSubscription
    "SandboxSubscription"                      = var.sandbox_azure_subscription_id
    "ManagedIdentityClientID"                  = var.useridentityclientid
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.useridentity]
  }

  site_config {
    ftps_state                             = "Disabled"
    minimum_tls_version                    = "1.2"
    application_insights_connection_string = var.AppInsightsConnectionString
    application_insights_key               = var.AppInsightsInstrumentationKey
    vnet_route_all_enabled                 = true
    scm_use_main_ip_restriction            = true
    application_stack {
      powershell_core_version = "7.2"
    }

    ip_restriction {
      action      = "Allow"
      name        = "AzureCloud"
      priority    = 100
      service_tag = "AzureCloud"
    }

    dynamic "ip_restriction" {
      for_each = var.ip_allowlist
      content {
        action     = "Allow"
        name       = ip_restriction.value.name
        priority   = ip_restriction.value.priority
        ip_address = "${ip_restriction.value.ip}/${ip_restriction.value.cidr}"
      }
    }

    cors {
      allowed_origins = ["http://localhost:3000", "https://${var.FrontendPortalURL}"]
    }
  }
}

## Application Code
data "archive_file" "function_app_code" {
  type        = "zip"
  source_dir  = "../App/BackendFunction"
  output_path = "../Temp/backendfunction.zip"
}

resource "null_resource" "function_app_publish" {
  provisioner "local-exec" {
    command = <<-EOT
    az webapp deployment source config-zip --resource-group ${var.resource_group_name} --name ${azurerm_windows_function_app.this.name} --src ${data.archive_file.function_app_code.output_path} --only-show-errors > ../Temp/output.txt  
    EOT

    interpreter = ["PowerShell", "-Command"]
  }
  triggers = {
    input_json    = filemd5(data.archive_file.function_app_code.output_path)
    deploy_target = azurerm_windows_function_app.this.id
  }
}

data "azurerm_function_app_host_keys" "deploykeys" {
  name                = azurerm_windows_function_app.this.name
  resource_group_name = var.resource_group_name
}
