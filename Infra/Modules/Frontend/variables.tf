variable "app_service_plan_frontend_name" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "web_app_frontend_name" {
  description = "The name of the Web App resource that hosts the frontend portal"
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

variable "api_management_gateway_url" {
  description = "The URL of the Azure API Management Gateway"
  type        = string
  default     = ""
}

variable "api_name" {
  description = "The name of the collection of APIs used by the platform"
  type        = string
  default     = ""
}

variable "api_create_url" {
  description = "The API to create new sandboxes"
  type        = string
  default     = ""
}

variable "api_list_url" {
  description = "The API to list the sandboxes of a user"
  type        = string
  default     = ""
}

variable "api_delete_url" {
  description = "The API to delete a sandbox for a user"
  type        = string
  default     = ""
}

variable "api_reset_url" {
  description = "The API to reset a sandbox for a user"
  type        = string
  default     = ""
}

variable "app_service_plan_id" {
  description = "The resource ID of the App Service Plan"
  type        = string
  default     = ""
}

variable "frontend_app_id" {
  description = "The ID of the Frontend Azure AD App Registration"
  type        = string
  default     = ""
}

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
