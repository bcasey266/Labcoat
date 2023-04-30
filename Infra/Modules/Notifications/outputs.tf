output "authorize" {
  description = "Manual step required on the first deploy of the platform"
  value       = "Please authorize the Logic App Office 365 Connection here: https://portal.azure.com/#@${var.azuread_tenant_id}/resource${azapi_resource.office365apiconnection.id}/edit"
}

output "queue_notifications" {
  description = "The name of the Queue used for sending notifications from the Logic App"
  value       = azurerm_storage_queue.notification.name
}
