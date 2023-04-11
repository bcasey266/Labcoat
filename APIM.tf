resource "azurerm_api_management" "this" {
  name                = var.APIMName
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Consumption_0"
  publisher_name      = "Brandon Casey"
  publisher_email     = "Brandon.casey@ahead.com"

  identity {
    type = "SystemAssigned"
  }
}

/* resource "azuread_application" "apim" {
  
} */
