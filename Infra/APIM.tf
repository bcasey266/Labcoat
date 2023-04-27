resource "azurerm_api_management" "this" {
  name                = var.APIMName
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Consumption_0"
  publisher_name      = var.APIMPublisherName
  publisher_email     = var.APIMPublisherEmail

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
  credentials {
    header = {
      "x-functions-key" = data.azurerm_function_app_host_keys.deploykeys.default_function_key
    }
  }
}

resource "azurerm_api_management_api" "this" {
  name                  = "sandbox"
  resource_group_name   = azurerm_resource_group.this.name
  api_management_name   = azurerm_api_management.this.name
  revision              = 1
  display_name          = "sandbox"
  path                  = "sandbox"
  protocols             = ["https"]
  subscription_required = false
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
<set-variable name="x-request-user-id" value="@(context.Request.Headers.GetValueOrDefault("Authorization","").Split(' ')[1].AsJwt()?.Claims["oid"].FirstOrDefault())" />
        <choose>
            <when condition="@(context.Request.Method.Equals("POST"))">
                <set-variable name="x-request-provided-id" value="@((string)context.Request.Body.As<JObject>(preserveContent: true).SelectToken("ObjectID"))" />
            </when>
            <when condition="@(context.Request.Method.Equals("GET"))">
                <set-variable name="x-request-provided-id" value="@((string)context.Request.Url.Query.GetValueOrDefault("ObjectID"))" />
            </when>
        </choose>
        <choose>
            <when condition="@(context.Variables.GetValueOrDefault<string>("x-request-provided-id").Equals(context.Variables.GetValueOrDefault<string>("x-request-user-id")))" />
            <otherwise>
                <return-response>
                    <set-status code="405" reason="Request Manipulated" />
                </return-response>
            </otherwise>
        </choose>
        <set-backend-service backend-id="${azurerm_api_management_backend.this.name}" />
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

resource "azurerm_api_management_api_operation" "list" {
  operation_id        = "list"
  api_name            = azurerm_api_management_api.this.name
  api_management_name = azurerm_api_management_api.this.api_management_name
  resource_group_name = azurerm_api_management_api.this.resource_group_name
  display_name        = "Get User Sandboxes"
  method              = "GET"
  url_template        = "/list"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "delete" {
  operation_id        = "delete"
  api_name            = azurerm_api_management_api.this.name
  api_management_name = azurerm_api_management_api.this.api_management_name
  resource_group_name = azurerm_api_management_api.this.resource_group_name
  display_name        = "Delete User Sandboxes"
  method              = "POST"
  url_template        = "/delete"

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "reset" {
  operation_id        = "reset"
  api_name            = azurerm_api_management_api.this.name
  api_management_name = azurerm_api_management_api.this.api_management_name
  resource_group_name = azurerm_api_management_api.this.resource_group_name
  display_name        = "Reset User Sandboxes"
  method              = "POST"
  url_template        = "/reset"

  response {
    status_code = 200
  }
}
