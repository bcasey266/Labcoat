output "AzureADAppAuthorization" {
  value = module.APIM.APIAdminConsent
}

output "Office365Authorization" {
  value = module.Notifications.Authorize
}
