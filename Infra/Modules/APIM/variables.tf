variable "FrontendApp" {
  type        = string
  description = "Frontend Azure AD App Registration Name"
}

variable "AppOwnerObjectID" {
  type        = string
  description = "Frontend Azure AD App Registration Name"
}

variable "location" {
  type        = string
  description = "The azure region to place resources in"
  default     = "eastus"
}

variable "ResourceGroupName" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "APIMName" {
  type        = string
  description = "Azure APIM Name for ASAP"
}

variable "APIMPublisherName" {
  type        = string
  description = "The admin's name in charge of APIM"
}

variable "APIMPublisherEmail" {
  type        = string
  description = "The admin's email in charge of APIM"
}

variable "FunctionAppName" {
  type        = string
  description = "Function App Name for ASAP"
}

variable "FunctionAppHostName" {
  type        = string
  description = "The admin's email in charge of APIM"
}

variable "FunctionAppHostKey" {
  type        = string
  description = "The admin's email in charge of APIM"
}

variable "AzureADTenantID" {
  type        = string
  description = "The admin's email in charge of APIM"
}
