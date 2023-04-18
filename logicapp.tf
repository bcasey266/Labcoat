resource "azapi_resource" "queueapiconnection" {
  type                      = "Microsoft.Web/connections@2016-06-01"
  schema_validation_enabled = false
  name                      = "queue"
  location                  = var.LogicAppLocation
  parent_id                 = azurerm_resource_group.this.id
  body = jsonencode({
    properties = {
      api = {
        name        = "azurequeues",
        displayName = "Azure Queues",
        id          = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Web/locations/${var.LogicAppLocation}/managedApis/azurequeues",
        type        = "Microsoft.Web/locations/managedApis"
      }
      parameterValueSet = {
        name = "managedIdentityAuth"
      }
    }
  })
  response_export_values = ["properties.api.id"]
}

resource "azapi_resource" "office365apiconnection" {
  type                      = "Microsoft.Web/connections@2016-06-01"
  schema_validation_enabled = false
  name                      = "office365"
  location                  = var.LogicAppLocation
  parent_id                 = azurerm_resource_group.this.id
  body = jsonencode({
    properties = {
      api = {
        name        = "office365",
        displayName = "Office 365 Outlook",
        id          = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Web/locations/${var.LogicAppLocation}/managedApis/office365",
        type        = "Microsoft.Web/locations/managedApis"
      }
    }
  })
  response_export_values = ["properties.api.id"]
}

resource "azurerm_logic_app_workflow" "this" {
  name                = var.LogicAppName
  location            = var.LogicAppLocation
  resource_group_name = azurerm_resource_group.this.name
  identity {
    type = "SystemAssigned"
  }
  parameters = {
    "$connections" = jsonencode(
      {
        (azapi_resource.queueapiconnection.name) = {
          connectionId   = azapi_resource.queueapiconnection.id
          connectionName = azapi_resource.queueapiconnection.name
          id             = jsondecode(azapi_resource.queueapiconnection.output).properties.api.id
          connectionProperties = {
            authentication = {
              type = "ManagedServiceIdentity"
            }
          }
        },
        (azapi_resource.office365apiconnection.name) = {
          connectionId   = azapi_resource.office365apiconnection.id
          connectionName = azapi_resource.office365apiconnection.name
          id             = jsondecode(azapi_resource.office365apiconnection.output).properties.api.id
        }
      }
    )
  }
  workflow_parameters = {
    "$connections" = jsonencode(
      {
        defaultValue = {}
        type         = "Object"
      }
    )
  }
}

resource "azurerm_storage_queue" "logicappqueue" {
  name                 = "logicappqueue"
  storage_account_name = azurerm_storage_account.this.name
}

resource "azurerm_role_assignment" "logicappQueueContributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_logic_app_workflow.this.identity[0].principal_id
}

resource "azurerm_logic_app_trigger_custom" "this" {
  name         = "queue-message"
  logic_app_id = azurerm_logic_app_workflow.this.id

  body = <<BODY
{
                "inputs": {
                    "host": {
                        "connection": {
                            "name": "@parameters('$connections')['${azapi_resource.queueapiconnection.name}']['connectionId']"
                        }
                    },
                    "method": "get",
                    "path": "/v2/storageAccounts/@{encodeURIComponent(encodeURIComponent('${azurerm_storage_account.this.name}'))}/queues/@{encodeURIComponent('${azurerm_storage_queue.logicappqueue.name}')}/message_trigger"
                },
                "recurrence": {
                    "frequency": "Minute",
                    "interval": 3
                },
                "splitOn": "@triggerBody()?['QueueMessagesList']?['QueueMessage']",
                "type": "ApiConnection"
}
BODY

}

resource "azurerm_logic_app_action_custom" "sendmail" {
  name         = "send-email"
  logic_app_id = azurerm_logic_app_workflow.this.id

  body = <<BODY
{
    "inputs": {
                    "body": {
                        "Body": "<p>@{triggerBody()?['MessageText']}</p>",
                        "Importance": "Normal",
                        "Subject": "Test Email",
                        "To": "brandon.casey@ahead.com"
                    },
                    "host": {
                        "connection": {
                            "name": "@parameters('$connections')['${azapi_resource.office365apiconnection.name}']['connectionId']"
                        }
                    },
                    "method": "post",
                    "path": "/v2/Mail"
                },
    "runAfter": {},
    "type": "ApiConnection"
}
BODY
}

resource "azurerm_logic_app_action_custom" "deletemessage" {
  name         = "delete-message"
  logic_app_id = azurerm_logic_app_workflow.this.id

  body = <<BODY
{
    "inputs": {
                    "host": {
                        "connection": {
                            "name": "@parameters('$connections')['${azapi_resource.queueapiconnection.name}']['connectionId']"
                        }
                    },
                    "method": "delete",
                    "path": "/v2/storageAccounts/@{encodeURIComponent(encodeURIComponent('${azurerm_storage_account.this.name}'))}/queues/@{encodeURIComponent('${azurerm_storage_queue.logicappqueue.name}')}/messages/@{encodeURIComponent(triggerBody()?['MessageId'])}",
                    "queries": {
                        "popreceipt": "@triggerBody()?['PopReceipt']"
                    }
                },
    "runAfter": {"${azurerm_logic_app_action_custom.sendmail.name}": [
                        "Succeeded"
                    ]},
    "type": "ApiConnection"
}
BODY
}

output "Authorize" {
  value = "Please authorize the Logic App Office 365 Connection here: https://portal.azure.com/#@${data.azuread_client_config.current.tenant_id}/resource${azapi_resource.office365apiconnection.id}/edit"
}
