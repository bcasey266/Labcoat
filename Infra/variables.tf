variable "sandbox_azure_subscription_id" {
  description = "The Azure Subscription ID that will host the Sandbox Resource Groups."
  type        = string
  default     = ""
}

variable "azuread_tenant_id" {
  description = "The Azure AD Tenant ID that is connected to the Sandbox Subscriptions."
  type        = string
  default     = ""
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
    name     = ""
    ip       = ""
    cidr     = 32
    priority = 1
  }]
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

variable "key_vault_name" {
  description = "The name of the Azure Key Vault used to store Platform level secrets"
  type        = string
  default     = ""

  validation {
    condition     = can(regex("[a-zA-Z0-9]+([-]?[a-zA-Z0-9]){3,24}", var.key_vault_name))
    error_message = "Azure Key Vaults can only contain up to 24 Alphanumerics and hyphens"
  }
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

variable "log_analytics_name" {
  description = "The name of the Log Analytics Workspace used for centralized logging"
  type        = string
  default     = ""
}

variable "application_insights_name" {
  description = "The name of the Application Insights resource used for centralized logging"
  type        = string
  default     = ""
}

variable "managed_identity_name" {
  description = "The name of the Managed Identity used for authentication and authorization within the platform"
  type        = string
  default     = ""
}

variable "vnet_name" {
  description = "Name of the VNET that will be created"
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

variable "app_service_plan_name" {
  description = "The name of the App Service Plan that will host the Fuctions used to manage the platform"
  type        = string
  default     = ""
}

variable "function_app_name" {
  description = "The name of the Function App that hosts the Functions for the platform"
  type        = string
  default     = ""
}

variable "enable_frontend" {
  description = "This boolean value will enable the pre-built frontend portal for Labcoat"
  type        = bool
  default     = true
}

variable "web_app_frontend_name" {
  description = "The name of the Web App resource that hosts the frontend portal"
  type        = string
  default     = ""
}

variable "enable_apim" {
  description = "This boolean value will enable the pre-built APIM resource for Labcoat"
  type        = bool
  default     = true
}

variable "api_management_name" {
  description = "Azure APIM Name for Labcoat"
  type        = string
  default     = ""
}

variable "api_management_admin_name" {
  description = "The name of a person or service account that is registered to the APIM resource"
  type        = string
  default     = ""
}

variable "api_management_admin_email" {
  description = "The email of a person or service account that is registered to the APIM resource"
  type        = string
  default     = ""
}

variable "frontend_app_registration_name" {
  description = "The name of the Azure AD App Registration for the Frontend Portal"
  type        = string
  default     = ""
}

variable "enable_notifications" {
  description = "This boolean value will enable built-in notification capabilities which will deploy out a Logic App with email templates"
  type        = bool
  default     = true
}

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
