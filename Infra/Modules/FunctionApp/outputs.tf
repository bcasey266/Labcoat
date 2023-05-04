output "function_app_host_name" {
  description = "The host name of the Function App"
  value       = azurerm_linux_function_app.this.default_hostname
}

output "function_app_name" {
  description = "The resource name of the Function App"
  value       = azurerm_linux_function_app.this.name
}

output "app_service_plan_id" {
  description = "The resource ID of the App Service Plan"
  value       = azurerm_service_plan.this.id
}
