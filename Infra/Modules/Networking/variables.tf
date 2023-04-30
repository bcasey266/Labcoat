variable "vnet_name" {
  description = "Name of the VNET that will be created if enable_private_networking is enabled"
  type        = string
  default     = ""
}

variable "region" {
  description = "The primary Azure region that the management resources will be placed in."
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "The name of the Resource Group that will hold the Sandbox Platform Management Resources"
  type        = string
  default     = ""
}

variable "vnet_ip_space" {
  description = "VNET IP configurations to host WebApp VNET Integration and Private Endpoints"
  type = object({
    vnetcidr            = list(string)
    privateendpointcidr = list(string)
    vnetintegrationcidr = list(string)
  })
  default = ({
    vnetcidr            = ["10.0.0.0/24"]
    privateendpointcidr = ["10.0.0.64/27"]
    vnetintegrationcidr = ["10.0.0.96/27"]
  })
}

variable "storage_account_name" {
  description = "The name of the Storage Account used to host the Tables, Queues, and Code for Sandbox Platform Management"
  type        = string
  default     = ""

  validation {
    condition     = can(regex("[a-z0-9]+([-]?[a-z0-9]){2,63}", var.storage_account_name))
    error_message = "Storage Accounts can only contain lowercase characters and numbers"
  }
}

variable "storage_account_id" {
  description = "The ID of the Storage Account used to host the Tables, Queues, and Code for Sandbox Platform Management"
  type        = string
  default     = ""
}

variable "key_vault_name" {
  description = "The name of the Azure Key Vault used to store Platform level secrets"
  type        = string
  default     = ""

  validation {
    condition     = can(regex("[a-zA-Z0-9]+([-]?[a-zA-Z0-9]){3,24}", var.key_vault_name))
    error_message = "Azure Key Vaults can only contain up to 24 Alphanumerics and hyphens"
  }
}

variable "key_vault_id" {
  description = "The ID of the Azure Key Vault used to store Platform level secrets"
  type        = string
  default     = ""
}
