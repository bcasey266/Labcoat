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
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Role"
    }
    resource_access {
      id   = "37f7f235-527c-4136-accd-4a02d197296e"
      type = "Role"
    }
    resource_access {
      id   = "14dad69e-099b-42c9-810b-d002981feec1"
      type = "Role"
    }
    resource_access {
      id   = "7427e0e9-2fba-42fe-b0c0-848c9e6a8182"
      type = "Role"
    }
  }
}

resource "azuread_application_pre_authorized" "frontendapp" {
  application_object_id = azuread_application.frontendapp.object_id
  authorized_app_id     = azuread_application.frontendapp.application_id
  permission_ids        = [random_uuid.frontendapp.result]
}
