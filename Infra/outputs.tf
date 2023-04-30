output "spn_api" {
  description = "Manual step required on the first deploy of the platform"
  value       = "Azure AD App Registration API Permissions: ${module.APIM.api_admin_consent}"
}

output "o365_auth" {
  description = "Manual step required on the first deploy of the platform"
  value       = "Office 365 Authorization: ${module.Notifications.authorize}"
}
