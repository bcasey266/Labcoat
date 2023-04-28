output "FunctionAppHostName" {
  value = azurerm_windows_function_app.this.default_hostname
}

output "FunctionAppHostKey" {
  value = data.azurerm_function_app_host_keys.deploykeys.default_function_key
}
