output "APIAdminConsent" {
  value = "Please consent to the Service Principal's API Permissions: https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnAPI/appId/${azuread_application.frontend_app_registration_name.application_id}/isMSAApp~/false"
}

output "FrontendAppID" {
  value = azuread_application.frontendapp.application_id
}

output "APIMGatewayURL" {
  value = azurerm_api_management.this.gateway_url
}

output "APIName" {
  value = azurerm_api_management_api.this.name
}

output "APICreateURL" {
  value = azurerm_api_management_api_operation.create.url_template
}

output "APIListURL" {
  value = azurerm_api_management_api_operation.list.url_template
}

output "APIDeleteURL" {
  value = azurerm_api_management_api_operation.delete.url_template
}

output "APIResetURL" {
  value = azurerm_api_management_api_operation.reset.url_template
}
