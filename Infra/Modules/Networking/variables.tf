variable "VNETName" {
  type = string
}

variable "location" {
  type        = string
  description = "The azure region to place resources in"
  default     = "eastus"
}

variable "ResourceGroupName" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "StorageAccountName" {
  type        = string
  description = "Storage Account Name for ASAP to host Tables and Queues"

  validation {
    condition     = can(regex("[a-z0-9]+([-]?[a-z0-9]){2,63}", var.StorageAccountName))
    error_message = "Storage Accounts can only contain lowercase characters and numbers"
  }
}

variable "StorageAccountID" {
  type = string
}

variable "KeyVaultName" {
  type = string
}

variable "KeyVaultID" {
  type = string
}
