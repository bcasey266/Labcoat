output "frontend_host_name" {
  description = "The host name of the frontend that hosts the ASAP Portal for the platform"
  value       = azurerm_linux_web_app.this.default_hostname
}

output "frontend_url" {
  description = "The URL of the Frontend Portal"
  value       = azurerm_linux_web_app.this.default_hostname
}
