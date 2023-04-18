### General Variables
variable "location" {
  type        = string
  description = "The azure region to place resources in"
  default     = "eastus"
}

variable "SandboxSubID" {
  type        = string
  description = "The Subscription ID of the Sandbox Subscription"
}

variable "AzureADTenantID" {
  type        = string
  description = "The Azure AD Tenant ID is utilized to create and manage App APIs"
}

variable "AdminIPs" {
  type        = list(any)
  description = "List of Admin IPs"
}

### management.tf Variables
variable "ResourceGroupName" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "KeyVaultName" {
  type        = string
  description = "Key Vault Name for ASAP to host secrets"

  validation {
    condition     = can(regex("[a-z0-9]+([-]?[a-z0-9]){3,24}", var.KeyVaultName))
    error_message = "Storage Accounts can only contain lowercase characters and numbers"
  }
}

variable "StorageAccountName" {
  type        = string
  description = "Storage Account Name for ASAP to host Tables and Queues"

  validation {
    condition     = can(regex("[a-z0-9]+([-]?[a-z0-9]){2,63}", var.StorageAccountName))
    error_message = "Storage Accounts can only contain lowercase characters and numbers"
  }
}

variable "LogAnalyticsName" {
  type        = string
  description = "Log Analytics Name for ASAP for logging"
}

variable "ApplicationInsightsName" {
  type        = string
  description = "Application Insights Workspace Name for ASAP for logging"
}

### network.tf Variables
variable "VNETName" {
  type        = string
  description = "VNET Name for ASAP"
}

### compute.tf Variables
variable "ServicePlanName" {
  type        = string
  description = "App Service Plan Name for ASAP"
}

variable "FunctionAppName" {
  type        = string
  description = "Function App Name for ASAP"
}

### frontend.tf Variables
variable "ServicePlanFEName" {
  type        = string
  description = "App Service Plan Frontend Name for ASAP"
}

variable "WebAppName" {
  type        = string
  description = "Web App Name for ASAP"
}

### APIM.tf Variables
variable "APIMName" {
  type        = string
  description = "Azure APIM Name for ASAP"
}

variable "FrontendApp" {
  type        = string
  description = "Frontend Azure AD App Registration Name"
}

### logicapp.tf Variables
variable "LogicAppName" {
  type        = string
  description = "Azure Logic App Name for ASAP"
}

variable "LogicAppLocation" {
  type        = string
  description = "The azure region to place resources in"
  default     = "eastus2"
}
