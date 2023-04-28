variable "region" {
  type        = string
  description = "The azure region to place resources in"
  default     = "eastus"
}

variable "sandbox_azure_subscription_id" {
  type        = string
  description = "The Subscription ID of the Sandbox Subscription"
}

variable "resource_group_name" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "storage_account_name" {
  type        = string
  description = "Storage Account Name for ASAP to host Tables and Queues"

  validation {
    condition     = can(regex("[a-z0-9]+([-]?[a-z0-9]){2,63}", var.storage_account_name))
    error_message = "Storage Accounts can only contain lowercase characters and numbers"
  }
}

variable "app_service_plan_name" {
  type        = string
  description = "App Service Plan Name for ASAP"
}

variable "function_app_name" {
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

variable "ip_allowlist" {
  description = "List of Public IPs that should be allowed to communicate with Azure Resources"
  type = list(object({
    name     = string
    ip       = string
    cidr     = number
    priority = number
  }))
  default = [{
    cidr     = 32
    ip       = ""
    name     = ""
    priority = 1
  }]
}

variable "AppInsightsID" {
  type = string
}

variable "AppInsightsConnectionString" {
  type = string
}

variable "AppInsightsInstrumentationKey" {
  type = string
}

variable "StorageQueueNotifications" {
  type = string
}

variable "FrontendPortalURL" {
  type = string
}
