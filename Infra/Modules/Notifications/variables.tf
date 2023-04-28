
variable "region" {
  type        = string
  description = "The azure region to place resources in"
  default     = "eastus"
}

variable "resource_group_name" {
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

variable "logic_app_name" {
  type = string
}

variable "FrontendPortalURL" {
  type = string
}

variable "sandbox_azure_subscription_id" {
  type        = string
  description = "The Subscription ID of the Sandbox Subscription"
}

variable "storage_account_name" {
  type        = string
  description = "Storage Account Name for ASAP to host Tables and Queues"

  validation {
    condition     = can(regex("[a-z0-9]+([-]?[a-z0-9]){2,63}", var.storage_account_name))
    error_message = "Storage Accounts can only contain lowercase characters and numbers"
  }
}

variable "StorageAccountID" {
  type = string
}

variable "TenantID" {
  type = string
}
