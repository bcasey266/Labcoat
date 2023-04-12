resource "random_uuid" "frontendapp" {}

resource "azuread_application" "frontendapp" {
  display_name     = var.FrontendApp
  identifier_uris  = ["api://${var.FrontendApp}"]
  owners           = [data.azuread_client_config.current.object_id]
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
    redirect_uris = ["http://localhost:3000/", "https://${azurerm_windows_web_app.this.default_hostname}/"]
  }
}

resource "azuread_application_pre_authorized" "frontendapp" {
  application_object_id = azuread_application.frontendapp.object_id
  authorized_app_id     = azuread_application.frontendapp.application_id
  permission_ids        = [random_uuid.frontendapp.result]
}
