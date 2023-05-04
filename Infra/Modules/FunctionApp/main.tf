resource "azurerm_service_plan" "this" {
  name                = var.app_service_plan_name
  location            = var.region
  resource_group_name = var.resource_group_name

  os_type  = "Linux"
  sku_name = "B1"
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

resource "azurerm_storage_table" "this" {
  name                 = "sandboxtable"
  storage_account_name = var.storage_account_name
}

resource "azurerm_linux_function_app" "this" {
  name                = var.function_app_name
  location            = var.region
  resource_group_name = var.resource_group_name

  storage_key_vault_secret_id     = var.storage_account_connection_string
  key_vault_reference_identity_id = var.user_identity_id
  service_plan_id                 = azurerm_service_plan.this.id
  https_only                      = true
  virtual_network_subnet_id       = var.subnet_integration_id
  builtin_logging_enabled         = false

  tags = {
    "hidden-link: /app-insights-conn-string"         = var.app_insights_connection_string
    "hidden-link: /app-insights-instrumentation-key" = var.app_insights_instrumentation_key
    "hidden-link: /app-insights-resource-id"         = var.app_insights_id
  }

  lifecycle {
    ignore_changes = [
      tags["hidden-link: /app-insights-resource-id"]
    ]
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"      = "1"
    "WEBSITE_CONTENTOVERVNET"       = 1
    "ResourceGroupName"             = var.resource_group_name
    "StorageAccountName"            = var.storage_account_name
    "StorageQueueNewSandbox"        = azurerm_storage_queue.newsandbox.name
    "StorageQueueDeleteSandbox"     = azurerm_storage_queue.deletesandbox.name
    "StorageQueueResetSandbox"      = azurerm_storage_queue.resetsandbox.name
    "NotificationsEnabled"          = var.enable_notifications
    "StorageQueueNotifications"     = var.queue_notifications
    "StorageTableSandbox"           = azurerm_storage_table.this.name
    "SandboxManagementSubscription" = var.platform_subscription_id
    "SandboxSubscription"           = var.sandbox_azure_subscription_id
    "ManagedIdentityClientID"       = var.user_identity_client_id
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_identity_id]
  }

  site_config {
    ftps_state                             = "Disabled"
    minimum_tls_version                    = "1.2"
    application_insights_connection_string = var.app_insights_connection_string
    application_insights_key               = var.app_insights_instrumentation_key
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
      allowed_origins = var.enable_frontend == true ? ["http://localhost:3000", "https://${var.frontend_url}"] : ["http://localhost:3000"]
    }
  }
}

data "archive_file" "this" {
  type        = "zip"
  source_dir  = "../App/BackendFunction"
  output_path = "../Temp/backendfunction.zip"
}

resource "null_resource" "this" {
  provisioner "local-exec" {
    command = <<-EOT
    az webapp deployment source config-zip --resource-group ${var.resource_group_name} --name ${azurerm_linux_function_app.this.name} --src ${data.archive_file.this.output_path} --only-show-errors > ../Temp/output.txt  
    EOT

    interpreter = ["PowerShell", "-Command"]
  }
  triggers = {
    input_json    = filemd5(data.archive_file.this.output_path)
    deploy_target = azurerm_linux_function_app.this.id
  }
}
