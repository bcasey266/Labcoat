output "function_app_host_name" {
  description = "The host name of the Function App"
  value       = azurerm_windows_function_app.this.default_hostname
}

output "function_app_name" {
  description = "The resource name of the Function App"
  value       = azurerm_windows_function_app.this.name
}
