output "subnet_integration_ids" {
  description = "The IDs of the Integration Subnets"
  value       = azurerm_subnet.vnet_integration.id
}
