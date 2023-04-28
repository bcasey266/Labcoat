variable "frontend_app_registration_name" {
  type        = string
  description = "Frontend Azure AD App Registration Name"
}

variable "AppOwnerObjectID" {
  type        = string
  description = "Frontend Azure AD App Registration Name"
}

variable "region" {
  type        = string
  description = "The azure region to place resources in"
  default     = "eastus"
}

variable "resource_group_name" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "api_management_name" {
  type        = string
  description = "Azure APIM Name for ASAP"
}

variable "api_management_admin_name" {
  type        = string
  description = "The admin's name in charge of APIM"
}

variable "api_management_admin_email" {
  type        = string
  description = "The admin's email in charge of APIM"
}

variable "function_app_name" {
  type        = string
  description = "Function App Name for ASAP"
}

variable "FunctionAppHostName" {
  type        = string
  description = "The admin's email in charge of APIM"
}

variable "FrontendHostname" {
  type = string
}

variable "FunctionAppHostKey" {
  type        = string
  description = "The admin's email in charge of APIM"
}

variable "azuread_tenant_id" {
  type        = string
  description = "The admin's email in charge of APIM"
}
