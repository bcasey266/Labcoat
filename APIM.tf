resource "azurerm_api_management" "this" {
  name                = var.APIMName
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Consumption_0"
  publisher_name      = "Brandon Casey"
  publisher_email     = "Brandon.casey@ahead.com"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_api_management_backend" "this" {
  name                = var.FunctionAppName
  resource_group_name = azurerm_resource_group.this.name
  api_management_name = azurerm_api_management.this.name
  protocol            = "http"
  url                 = "https://${azurerm_windows_function_app.this.default_hostname}/api"
  resource_id         = azurerm_windows_function_app.this.id
  credentials {
    header = {
      "x-functions-key" = data.azurerm_function_app_host_keys.deploykeys.default_function_key
    }
  }
}

resource "azurerm_api_management_api" "this" {
  name                = "sandbox2"
  resource_group_name = azurerm_resource_group.this.name
  api_management_name = azurerm_api_management.this.name
  revision            = 1
  display_name        = "sandbox2"
  path                = "sandbox2"
  protocols           = ["https"]
}

resource "azurerm_api_management_api_policy" "this" {
  api_name            = azurerm_api_management_api.this.name
  api_management_name = azurerm_api_management_api.this.api_management_name
  resource_group_name = azurerm_api_management_api.this.resource_group_name

  xml_content = <<XML
<policies>
    <inbound>
        <cors allow-credentials="true">
            <allowed-origins>
                <origin>http://localhost:3000/</origin>
                <origin>https://${azurerm_windows_web_app.this.default_hostname}/</origin>
            </allowed-origins>
            <allowed-methods preflight-result-max-age="300">
                <method>GET</method>
                <method>POST</method>
                <method>DELETE</method>
            </allowed-methods>
            <allowed-headers>
                <header>content-type</header>
                <header>Authorization</header>
            </allowed-headers>
        </cors>
        <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized">
            <openid-config url="https://login.microsoftonline.com/${var.AzureADTenantID}/v2.0/.well-known/openid-configuration" />
            <required-claims>
                <claim name="aud">
                    <value>${azuread_application.frontendapp.application_id}</value>
                </claim>
            </required-claims>
        </validate-jwt>
        <base />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
XML
}

resource "azurerm_api_management_api_operation" "create" {
  operation_id        = "create"
  api_name            = azurerm_api_management_api.this.name
  api_management_name = azurerm_api_management_api.this.api_management_name
  resource_group_name = azurerm_api_management_api.this.resource_group_name
  display_name        = "Create Sandbox"
  method              = "POST"
  url_template        = "/create"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation_policy" "example" {
  api_name            = azurerm_api_management_api.this.name
  api_management_name = azurerm_api_management_api.this.api_management_name
  resource_group_name = azurerm_api_management_api.this.resource_group_name
  operation_id        = azurerm_api_management_api_operation.create.operation_id

  xml_content = <<XML
<policies>
    <inbound>
        <base />
        <set-backend-service id="sandbox" backend-id="${azurerm_api_management_backend.this.name}" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
XML
}
