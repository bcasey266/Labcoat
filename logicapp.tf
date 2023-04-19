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
    "$connections" = jsonencode({
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
    })
  }
  workflow_parameters = {
    "$connections" = jsonencode({
      defaultValue = {}
      type         = "Object"
    }),
    "frontend" : jsonencode({
      "defaultValue" : "https://${azurerm_windows_web_app.this.default_hostname}/",
      "type" : "String"
    })
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

  body = jsonencode({
    "inputs" : {
      "host" : {
        "connection" : {
          "name" : "@parameters('$connections')['${azapi_resource.queueapiconnection.name}']['connectionId']"
        }
      },
      "method" : "get",
      "path" : "/v2/storageAccounts/@{encodeURIComponent(encodeURIComponent('${azurerm_storage_account.this.name}'))}/queues/@{encodeURIComponent('${azurerm_storage_queue.logicappqueue.name}')}/message_trigger"
    },
    "recurrence" : {
      "frequency" : "Minute",
      "interval" : 3
    },
    "splitOn" : "@triggerBody()?['QueueMessagesList']?['QueueMessage']",
    "type" : "ApiConnection"
  })
}

resource "azurerm_logic_app_action_custom" "ParseJSON" {
  name         = "Parse_JSON"
  logic_app_id = azurerm_logic_app_workflow.this.id

  body = jsonencode({
    "inputs" : {
      "content" : "@triggerBody()?['MessageText']",
      "schema" : {
        "properties" : {
          "Budget" : {
            "type" : "string"
          },
          "CostCenter" : {
            "type" : "string"
          },
          "Email" : {
            "type" : "string"
          },
          "FirstName" : {
            "type" : "string"
          },
          "LastName" : {
            "type" : "string"
          },
          "Length" : {
            "type" : "string"
          },
          "ManagerEmail" : {
            "type" : "string"
          },
          "NotificationType" : {
            "type" : "string"
          },
          "SandboxName" : {
            "type" : "string"
          },
          "DeleteOn" : {
            "type" : "string"
          }
        },
        "type" : "object"
      }
    },
    "runAfter" : {},
    "type" : "ParseJson"
  })
}

resource "azurerm_logic_app_action_custom" "bodyvariable" {
  name         = "body"
  logic_app_id = azurerm_logic_app_workflow.this.id

  body = jsonencode({
    "inputs" = {
      "variables" = [
        {
          "name"  = "body",
          "type"  = "string",
          "value" = "${file("CommunicationCode/index.html")}"
        }
      ]
    },
    "runAfter" = {
      "${azurerm_logic_app_action_custom.ParseJSON.name}" : [
        "Succeeded"
      ]
    },
    "type" = "InitializeVariable"
  })
}

resource "azurerm_logic_app_action_custom" "switch" {
  name         = "switch"
  logic_app_id = azurerm_logic_app_workflow.this.id

  body = jsonencode({
    "cases" : {
      "Case" : {
        "actions" : {
          "send-email" : {
            "inputs" : {
              "body" : {
                "Body" : "<p>@{variables('${azurerm_logic_app_action_custom.bodyvariable.name}')}</p>",
                "Subject" : "New Sandbox: @{body('${azurerm_logic_app_action_custom.ParseJSON.name}')?['SandboxName']}",
                "To" : "@body('${azurerm_logic_app_action_custom.ParseJSON.name}')?['Email']",
                "Importance" : "Normal"
              },
              "host" : {
                "connection" : {
                  "name" : "@parameters('$connections')['${azapi_resource.office365apiconnection.name}']['connectionId']"
                }
              },
              "method" : "post",
              "path" : "/v2/Mail"
            },
            "runAfter" : {},
            "type" : "ApiConnection"
          }
        },
        "case" : "New"
      }
    },
    "default" : {
      "actions" : {}
    },
    "expression" : "@body('${azurerm_logic_app_action_custom.ParseJSON.name}')?['NotificationType']",
    "runAfter" : {
      "${azurerm_logic_app_action_custom.bodyvariable.name}" : [
        "Succeeded"
      ]
    },
    "type" : "Switch"
  })
}

/* resource "azurerm_logic_app_action_custom" "sendmail" {
  name         = "send-email"
  logic_app_id = azurerm_logic_app_workflow.this.id

  body = jsonencode({

})
} */



resource "azurerm_logic_app_action_custom" "deletemessage" {
  name         = "delete-message"
  logic_app_id = azurerm_logic_app_workflow.this.id

  body = jsonencode({
    "inputs" : {
      "host" : {
        "connection" : {
          "name" : "@parameters('$connections')['${azapi_resource.queueapiconnection.name}']['connectionId']"
        }
      },
      "method" : "delete",
      "path" : "/v2/storageAccounts/@{encodeURIComponent(encodeURIComponent('${azurerm_storage_account.this.name}'))}/queues/@{encodeURIComponent('${azurerm_storage_queue.logicappqueue.name}')}/messages/@{encodeURIComponent(triggerBody()?['MessageId'])}",

      "queries" : {
        "popreceipt" : "@triggerBody()?['PopReceipt']"
      }
    },
    "runAfter" : {
      "${azurerm_logic_app_action_custom.switch.name}" : [
        "Succeeded"
      ]
    },
    "type" : "ApiConnection"
  })
}

output "Authorize" {
  value = "Please authorize the Logic App Office 365 Connection here: https://portal.azure.com/#@${data.azuread_client_config.current.tenant_id}/resource${azapi_resource.office365apiconnection.id}/edit"
}
