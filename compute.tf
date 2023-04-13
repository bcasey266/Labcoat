resource "azurerm_service_plan" "this" {
  name                = var.ServicePlanName
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  os_type  = "Windows"
  sku_name = "EP1"
}

resource "azurerm_storage_share" "this" {
  name                 = var.FunctionAppName
  storage_account_name = azurerm_storage_account.this.name
  quota                = 50
}

resource "azurerm_storage_queue" "newsandbox" {
  name                 = "newsandbox"
  storage_account_name = azurerm_storage_account.this.name
}

resource "azurerm_storage_queue" "deletesandbox" {
  name                 = "deletesandbox"
  storage_account_name = azurerm_storage_account.this.name
}

resource "azurerm_storage_table" "sandboxtable" {
  name                 = "sandboxtable"
  storage_account_name = azurerm_storage_account.this.name
}

resource "azurerm_storage_table" "counter" {
  name                 = "counter"
  storage_account_name = azurerm_storage_account.this.name
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

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"                 = "1"
    "WEBSITE_CONTENTSHARE"                     = azurerm_storage_share.this.name
    "WEBSITE_CONTENTOVERVNET"                  = 1
    "WEBSITE_SKIP_CONTENTSHARE_VALIDATION"     = 1
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.sandboxmgmtstorage.versionless_id})"
    "ResourceGroupName"                        = azurerm_resource_group.this.name
    "StorageAccountName"                       = azurerm_storage_account.this.name
    "StorageQueueNewSandbox"                   = azurerm_storage_queue.newsandbox.name
    "StorageQueueDeleteSandbox"                = azurerm_storage_queue.deletesandbox.name
    "StorageTableSandbox"                      = azurerm_storage_table.sandboxtable.name
    "StorageTableCounter"                      = azurerm_storage_table.counter.name
    "SandboxManagementSubscription"            = split("/", azurerm_resource_group.this.id)[2]
    "SandboxSubscription"                      = var.SandboxSubID
    "ManagedIdentityClientID"                  = azurerm_user_assigned_identity.this.client_id
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
      name       = "Gjon"
      priority   = 1
      ip_address = "${var.AdminIPs[0]}/32"
    }

    ip_restriction {
      action     = "Allow"
      name       = "Brandon"
      priority   = 2
      ip_address = "${var.AdminIPs[1]}/32"
    }

    ip_restriction {
      action      = "Allow"
      name        = "AzureCloud"
      priority    = 3
      service_tag = "AzureCloud"
    }

    /* dynamic "ip_restriction" {
      for_each = var.AdminIPs
      content {
        action     = "Allow"
        name       = ip_restriction.value
        priority   = ip_restriction.key + 1
        ip_address = "${ip_restriction.value}/32"
      }
    } */

    cors {
      allowed_origins = ["http://localhost:3000", "https://${azurerm_windows_web_app.this.default_hostname}"]
    }
  }
}

## Application Code
data "archive_file" "function_app_code" {
  type        = "zip"
  source_dir  = "BackendCode"
  output_path = "Temp/backendcode.zip"
}

locals {
  publish_backendcode_command = "az webapp deployment source config-zip --resource-group ${azurerm_resource_group.this.name} --name ${azurerm_windows_function_app.this.name} --src ${data.archive_file.function_app_code.output_path} --only-show-errors > temp/output.txt"
}

resource "null_resource" "function_app_publish" {
  provisioner "local-exec" {
    command = local.publish_backendcode_command
  }
  depends_on = [local.publish_backendcode_command]
  triggers = {
    input_json                  = filemd5(data.archive_file.function_app_code.output_path)
    publish_backendcode_command = local.publish_backendcode_command
    deploy_target               = azurerm_windows_function_app.this.id
  }
}

data "azurerm_function_app_host_keys" "deploykeys" {
  name                = azurerm_windows_function_app.this.name
  resource_group_name = azurerm_resource_group.this.name
}
