output "authorize" {
  description = "Manual step required on the first deploy of the platform"
  value       = var.email_service == "office365" ? "Please authorize the Logic App Office 365 Connection here: https://portal.azure.com/#@${var.azuread_tenant_id}/resource${azapi_resource.office365apiconnection[0].id}/edit" : "Please authorize the Logic App Outlook Connection here: https://portal.azure.com/#@${var.azuread_tenant_id}/resource${azapi_resource.outlookapiconnection[0].id}/edit"
}

output "queue_notifications" {
  description = "The name of the Queue used for sending notifications from the Logic App"
  value       = azurerm_storage_queue.notification.name
}
