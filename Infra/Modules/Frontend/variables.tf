variable "location" {
  type        = string
  description = "The azure region to place resources in"
  default     = "eastus"
}

variable "ResourceGroupName" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "ServicePlanFEName" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "WebAppName" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "FrontendAppID" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "AzureADTenantID" {
  type        = string
  description = "Resource Group Name for ASAP that contains the platform level resources"
}

variable "SandboxSubID" {
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
