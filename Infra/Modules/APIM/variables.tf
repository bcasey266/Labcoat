variable "api_management_name" {
  description = "Azure APIM Name for ASAP"
  type        = string
  default     = ""
}

variable "frontend_app_registration_name" {
  description = "The name of the Azure AD App Registration for the Frontend Portal"
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

variable "function_app_name" {
  description = "The name of the Function App that hosts the Functions for the platform"
  type        = string
  default     = ""
}

variable "function_app_host_name" {
  description = "The host name of the Function App that hosts the Functions for the platform"
  type        = string
  default     = ""
}

variable "function_app_host_key" {
  description = "The host key that authorizes requests to the Function App for the platform"
  type        = string
  default     = ""
}

variable "frontend_host_name" {
  description = "The host name of the frontend that hosts the ASAP Portal for the platform"
  type        = string
  default     = ""
}

variable "azuread_tenant_id" {
  description = "The Azure AD Tenant ID that is connected to the Sandbox Subscriptions."
  type        = string
  default     = ""
}
