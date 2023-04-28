resource "random_uuid" "frontendapp" {}

resource "azuread_application" "frontendapp" {
  display_name     = var.FrontendApp
  identifier_uris  = ["api://${var.FrontendApp}"]
  owners           = [var.AppOwnerObjectID]
  sign_in_audience = "AzureADMyOrg"

  api {
    requested_access_token_version = 2
    oauth2_permission_scope {
      admin_consent_description  = "Allow App to Read AD"
      admin_consent_display_name = "Consent Acknowledgement"
      enabled                    = true
      id                         = random_uuid.frontendapp.result
      type                       = "User"
      value                      = "Sandbox.Create"
    }
  }
  single_page_application {
    redirect_uris = ["http://localhost:3000/" //, "https://${azurerm_windows_web_app.this.default_hostname}/"
    ]
  }
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }
    resource_access {
      id   = "37f7f235-527c-4136-accd-4a02d197296e"
      type = "Scope"
    }
    resource_access {
      id   = "14dad69e-099b-42c9-810b-d002981feec1"
      type = "Scope"
    }
    resource_access {
      id   = "7427e0e9-2fba-42fe-b0c0-848c9e6a8182"
      type = "Scope"
    }
  }
}

resource "azuread_application_pre_authorized" "frontendapp" {
  application_object_id = azuread_application.frontendapp.object_id
  authorized_app_id     = azuread_application.frontendapp.application_id
  permission_ids        = [random_uuid.frontendapp.result]
}

resource "azurerm_api_management" "this" {
  name                = var.APIMName
  location            = var.location
  resource_group_name = var.ResourceGroupName
  sku_name            = "Consumption_0"
  publisher_name      = var.APIMPublisherName
  publisher_email     = var.APIMPublisherEmail

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_api_management_backend" "this" {
  name                = var.FunctionAppName
  resource_group_name = var.ResourceGroupName
  api_management_name = azurerm_api_management.this.name
  protocol            = "http"
  url                 = "https://${var.FunctionAppHostName}/api"
  credentials {
    header = {
      "x-functions-key" = var.FunctionAppHostKey
    }
  }
}

resource "azurerm_api_management_api" "this" {
  name                  = "sandbox"
  resource_group_name   = var.ResourceGroupName
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
  resource_group_name = var.ResourceGroupName

  xml_content = <<XML
<policies>
    <inbound>
        <cors allow-credentials="true">
            <allowed-origins>
                <origin>http://localhost:3000/</origin>
                <origin>https://${var.FunctionAppHostName}/</origin>
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
  resource_group_name = var.ResourceGroupName
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
  resource_group_name = var.ResourceGroupName
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
  resource_group_name = var.ResourceGroupName
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
  resource_group_name = var.ResourceGroupName
  display_name        = "Reset User Sandboxes"
  method              = "POST"
  url_template        = "/reset"

  response {
    status_code = 200
  }
}
