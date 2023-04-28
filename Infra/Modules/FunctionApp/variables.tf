variable "location" {
  type        = string
  description = "The azure region to place resources in"
  default     = "eastus"
}

variable "SandboxSubID" {
  type        = string
  description = "The Subscription ID of the Sandbox Subscription"
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

variable "ServicePlanName" {
  type        = string
  description = "App Service Plan Name for ASAP"
}

variable "FunctionAppName" {
  type        = string
  description = "Function App Name for ASAP"
}

variable "SubnetID" {
  type = string
}

variable "keyvaultsecret" {
  type = string
}

variable "useridentity" {
  type = string
}

variable "useridentityclientid" {
  type = string
}

variable "SandboxManagementSubscription" {
  type = string
}

variable "AdminIPs" {
  type        = list(any)
  description = "List of Admin IPs"
}
