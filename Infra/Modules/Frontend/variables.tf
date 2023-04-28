variable "region" {
  type        = string
  description = "The azure region to place resources in"
  default     = "eastus"
}

variable "resource_group_name" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "app_service_plan_frontend_name" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "web_app_name" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "FrontendAppID" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "azuread_tenant_id" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "sandbox_azure_subscription_id" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "APIMGatewayURL" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "APIName" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "APICreateURL" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "APIListURL" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "APIDeleteURL" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "APIResetURL" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}
