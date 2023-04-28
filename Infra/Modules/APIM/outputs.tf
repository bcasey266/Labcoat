output "APIAdminConsent" {
  value = "Please consent to the Service Principal's API Permissions: https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnAPI/appId/${azuread_application.frontendapp.application_id}/isMSAApp~/false"
}
