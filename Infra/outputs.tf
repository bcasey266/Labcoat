output "api_admin_consent" {
  description = "Manual step required on the first deploy of the platform"
  value       = module.APIM.api_admin_consent
}

output "Office365Authorization" {
  description = "Manual step required on the first deploy of the platform"
  value       = module.Notifications.authorize
}
