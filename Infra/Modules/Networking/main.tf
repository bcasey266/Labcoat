resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.region
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/24"]

}

resource "azurerm_subnet" "privateendpoint" {
  name                 = "subnet-pep"
  virtual_network_name = azurerm_virtual_network.this.name
  resource_group_name  = azurerm_virtual_network.this.resource_group_name
  address_prefixes     = ["10.0.0.64/27"]
}

resource "azurerm_subnet" "vnetintegration" {
  name                 = "vnet-integration"
  virtual_network_name = azurerm_virtual_network.this.name
  resource_group_name  = azurerm_virtual_network.this.resource_group_name
  address_prefixes     = ["10.0.0.96/27"]

  delegation {
    name = "vnet-integration"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }

  }
}

### Key Vault
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_virtual_network.this.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvaultlink" {
  name                  = "ManagementVNET"
  resource_group_name   = azurerm_virtual_network.this.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = azurerm_virtual_network.this.id
}

resource "azurerm_private_endpoint" "keyvault" {
  name                = "${var.key_vault_name}-pe"
  location            = var.region
  resource_group_name = azurerm_virtual_network.this.resource_group_name
  subnet_id           = azurerm_subnet.privateendpoint.id

  private_service_connection {
    name                           = "${var.key_vault_name}-pe"
    private_connection_resource_id = var.KeyVaultID
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${var.key_vault_name}-pe"
    private_dns_zone_ids = ["${azurerm_private_dns_zone.keyvault.id}"]
  }
}

### Storage Table
resource "azurerm_private_dns_zone" "table" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_virtual_network.this.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "tablelink" {
  name                  = "ManagementVNET"
  resource_group_name   = azurerm_virtual_network.this.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.table.name
  virtual_network_id    = azurerm_virtual_network.this.id
}

resource "azurerm_private_endpoint" "sandboxmgmtstoragetable" {
  name                = "${var.storage_account_name}-table-pe"
  location            = var.region
  resource_group_name = azurerm_virtual_network.this.resource_group_name
  subnet_id           = azurerm_subnet.privateendpoint.id

  private_service_connection {
    name                           = "${var.storage_account_name}-table-pe"
    private_connection_resource_id = var.StorageAccountID
    subresource_names              = ["table"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${var.storage_account_name}-table-pe"
    private_dns_zone_ids = ["${azurerm_private_dns_zone.table.id}"]
  }
}

### Storage Blob
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_virtual_network.this.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "bloblink" {
  name                  = "ManagementVNET"
  resource_group_name   = azurerm_virtual_network.this.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.this.id
}

resource "azurerm_private_endpoint" "sandboxmgmtstorageblob" {
  name                = "${var.storage_account_name}-blob-pe"
  location            = var.region
  resource_group_name = azurerm_virtual_network.this.resource_group_name
  subnet_id           = azurerm_subnet.privateendpoint.id

  private_service_connection {
    name                           = "${var.storage_account_name}-blob-pe"
    private_connection_resource_id = var.StorageAccountID
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${var.storage_account_name}-blob-pe"
    private_dns_zone_ids = ["${azurerm_private_dns_zone.blob.id}"]
  }
}

### Storage File
resource "azurerm_private_dns_zone" "file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_virtual_network.this.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "filelink" {
  name                  = "ManagementVNET"
  resource_group_name   = azurerm_virtual_network.this.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.file.name
  virtual_network_id    = azurerm_virtual_network.this.id
}

resource "azurerm_private_endpoint" "sandboxmgmtstoragefile" {
  name                = "${var.storage_account_name}-file-pe"
  location            = var.region
  resource_group_name = azurerm_virtual_network.this.resource_group_name
  subnet_id           = azurerm_subnet.privateendpoint.id

  private_service_connection {
    name                           = "${var.storage_account_name}-file-pe"
    private_connection_resource_id = var.StorageAccountID
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${var.storage_account_name}-file-pe"
    private_dns_zone_ids = ["${azurerm_private_dns_zone.file.id}"]
  }
}

### Storage Queue
resource "azurerm_private_dns_zone" "queue" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = azurerm_virtual_network.this.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "queuelink" {
  name                  = "ManagementVNET"
  resource_group_name   = azurerm_virtual_network.this.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.queue.name
  virtual_network_id    = azurerm_virtual_network.this.id
}

resource "azurerm_private_endpoint" "sandboxmgmtstoragequeue" {
  name                = "${var.storage_account_name}-queue-pe"
  location            = var.region
  resource_group_name = azurerm_virtual_network.this.resource_group_name
  subnet_id           = azurerm_subnet.privateendpoint.id

  private_service_connection {
    name                           = "${var.storage_account_name}-queue-pe"
    private_connection_resource_id = var.StorageAccountID
    subresource_names              = ["queue"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${var.storage_account_name}-queue-pe"
    private_dns_zone_ids = ["${azurerm_private_dns_zone.queue.id}"]
  }
}
