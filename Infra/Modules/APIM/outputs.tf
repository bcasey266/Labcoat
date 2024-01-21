output "api_admin_consent" {
  description = "Manual step required on the first deploy of the platform"
  value       = "Please consent to the App Registrations's API Permissions: https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnAPI/appId/${azuread_application.this.client_id}/isMSAApp~/false"
}

output "frontend_app_id" {
  description = "The ID of the Frontend Azure AD App Registration"
  value       = azuread_application.this.client_id
}

output "api_management_gateway_url" {
  description = "The URL of the Azure API Management Gateway"
  value       = azurerm_api_management.this.gateway_url
}

output "api_name" {
  description = "The name of the collection of APIs used by the platform"
  value       = azurerm_api_management_api.this.name
}

output "api_create_url" {
  description = "The API to create new sandboxes"
  value       = azurerm_api_management_api_operation.create.url_template
}

output "api_list_url" {
  description = "The API to list the sandboxes of a user"
  value       = azurerm_api_management_api_operation.list.url_template
}

output "api_delete_url" {
  description = "The API to delete a sandbox for a user"
  value       = azurerm_api_management_api_operation.delete.url_template
}

output "api_reset_url" {
  description = "The API to reset a sandbox for a user"
  value       = azurerm_api_management_api_operation.reset.url_template
}
