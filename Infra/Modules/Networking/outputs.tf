output "subnet_integration_id" {
  description = "The ID of the Integration Subnets"
  value       = azurerm_subnet.vnet_integration.id
}
