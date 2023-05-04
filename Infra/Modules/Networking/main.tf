resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.region
  resource_group_name = var.resource_group_name

  address_space = var.vnet_ip_space.vnetcidr
}

resource "azurerm_subnet" "private_endpoint" {
  name                 = "subnet-pep"
  resource_group_name  = azurerm_virtual_network.this.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name

  address_prefixes = var.vnet_ip_space.privateendpointcidr
}

resource "azurerm_subnet" "vnet_integration" {
  name                 = "vnet-integration"
  resource_group_name  = azurerm_virtual_network.this.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name

  address_prefixes = var.vnet_ip_space.vnetintegrationcidr

  delegation {
    name = "vnet-integration"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_private_dns_zone" "key_vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_virtual_network.this.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "key_vault_link" {
  name                = var.vnet_name
  resource_group_name = azurerm_virtual_network.this.resource_group_name

  private_dns_zone_name = azurerm_private_dns_zone.key_vault.name
  virtual_network_id    = azurerm_virtual_network.this.id
}

resource "azurerm_private_endpoint" "key_vault" {
  name                = "${var.key_vault_name}-pe"
  location            = var.region
  resource_group_name = azurerm_virtual_network.this.resource_group_name

  subnet_id = azurerm_subnet.private_endpoint.id

  private_service_connection {
    name                           = "${var.key_vault_name}-pe"
    private_connection_resource_id = var.key_vault_id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${var.key_vault_name}-pe"
    private_dns_zone_ids = ["${azurerm_private_dns_zone.key_vault.id}"]
  }
}

resource "azurerm_private_dns_zone" "table" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_virtual_network.this.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "table_link" {
  name                = var.vnet_name
  resource_group_name = azurerm_virtual_network.this.resource_group_name

  private_dns_zone_name = azurerm_private_dns_zone.table.name
  virtual_network_id    = azurerm_virtual_network.this.id
}

resource "azurerm_private_endpoint" "table" {
  name                = "${var.storage_account_name}-table-pe"
  location            = var.region
  resource_group_name = azurerm_virtual_network.this.resource_group_name

  subnet_id = azurerm_subnet.private_endpoint.id

  private_service_connection {
    name                           = "${var.storage_account_name}-table-pe"
    private_connection_resource_id = var.storage_account_id
    subresource_names              = ["table"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${var.storage_account_name}-table-pe"
    private_dns_zone_ids = ["${azurerm_private_dns_zone.table.id}"]
  }
}

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_virtual_network.this.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_link" {
  name                = var.vnet_name
  resource_group_name = azurerm_virtual_network.this.resource_group_name

  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.this.id
}

resource "azurerm_private_endpoint" "blob" {
  name                = "${var.storage_account_name}-blob-pe"
  location            = var.region
  resource_group_name = azurerm_virtual_network.this.resource_group_name

  subnet_id = azurerm_subnet.private_endpoint.id

  private_service_connection {
    name                           = "${var.storage_account_name}-blob-pe"
    private_connection_resource_id = var.storage_account_id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${var.storage_account_name}-blob-pe"
    private_dns_zone_ids = ["${azurerm_private_dns_zone.blob.id}"]
  }
}

resource "azurerm_private_dns_zone" "queue" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = azurerm_virtual_network.this.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "queuelink" {
  name                = var.vnet_name
  resource_group_name = azurerm_virtual_network.this.resource_group_name

  private_dns_zone_name = azurerm_private_dns_zone.queue.name
  virtual_network_id    = azurerm_virtual_network.this.id
}

resource "azurerm_private_endpoint" "queue" {
  name                = "${var.storage_account_name}-queue-pe"
  location            = var.region
  resource_group_name = azurerm_virtual_network.this.resource_group_name

  subnet_id = azurerm_subnet.private_endpoint.id

  private_service_connection {
    name                           = "${var.storage_account_name}-queue-pe"
    private_connection_resource_id = var.storage_account_id
    subresource_names              = ["queue"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${var.storage_account_name}-queue-pe"
    private_dns_zone_ids = ["${azurerm_private_dns_zone.queue.id}"]
  }
}
