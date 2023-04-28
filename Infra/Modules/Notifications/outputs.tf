output "Authorize" {
  value = "Please authorize the Logic App Office 365 Connection here: https://portal.azure.com/#@${var.TenantID}/resource${azapi_resource.office365apiconnection.id}/edit"
}

output "StorageQueueNotifications" {
  value = azurerm_storage_queue.notification.name
}
