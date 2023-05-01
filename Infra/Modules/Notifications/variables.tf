variable "logic_app_name" {
  description = "The name of the Logic App resource used for notifications"
  type        = string
  default     = ""
}

variable "logic_app_region" {
  description = "The region that hosts the Logic App. This is different due to allowlist restrictions on the Storage Account"
  type        = string
  default     = "eastus2"
}

variable "resource_group_name" {
  description = "The name of the Resource Group that will hold the Sandbox Platform Management Resources"
  type        = string
  default     = ""
}

variable "resource_group_id" {
  description = "The Resource ID of the Resource Group that will hold the Sandbox Platform Management Resources"
  type        = string
  default     = ""
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

variable "azuread_tenant_id" {
  description = "The Azure AD Tenant ID that is connected to the Sandbox Subscriptions."
  type        = string
  default     = ""
}

variable "platform_subscription_id" {
  description = "The ID of the Platform Subscription that hosts the Sandbox Management Resources"
  type        = string
  default     = ""
}

variable "sandbox_azure_subscription_id" {
  description = "The Azure Subscription ID that will host the Sandbox Resource Groups."
  type        = string
  default     = ""
}

variable "enable_frontend" {
  description = "This boolean value will enable the pre-built frontend portal for ASAP"
  type        = bool
  default     = true
}

variable "frontend_url" {
  description = "The URL of the Frontend Portal"
  type        = string
  default     = ""
}
