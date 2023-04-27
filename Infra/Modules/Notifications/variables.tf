
variable "location" {
  type        = string
  description = "The azure region to place resources in"
  default     = "eastus"
}

variable "ResourceGroupName" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "ResourceGroupID" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "SandboxManagementSubscription" {
  type = string
}

variable "LogicAppName" {
  type = string
}

variable "FrontendPortalURL" {
  type = string
}

variable "SandboxSubID" {
  type        = string
  description = "The Subscription ID of the Sandbox Subscription"
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

variable "TenantID" {
  type = string
}
