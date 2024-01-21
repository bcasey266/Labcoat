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

variable "storage_account_name" {
  description = "The name of the Storage Account used to host the Tables, Queues, and Code for Sandbox Platform Management"
  type        = string
  default     = ""

  validation {
    condition     = can(regex("[a-z0-9]+([-]?[a-z0-9]){2,63}", var.storage_account_name))
    error_message = "Storage Accounts can only contain lowercase characters and numbers"
  }
}

variable "storage_account_connection_string" {
  description = "The Storage Account Connection String used to connect Function App to Storage Account"
  type        = string
  default     = ""
}

variable "enable_notifications" {
  description = "This boolean value will enable built-in notification capabilities which will deploy out a Logic App with email templates"
  type        = bool
  default     = true
}

variable "queue_notifications" {
  description = "The name of the Queue used for sending notifications from the Logic App"
  type        = string
  default     = ""
}

variable "subnet_integration_id" {
  description = "The ID of the Integration Subnet"
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

variable "user_identity_id" {
  description = "The Resource ID of the User Managed Identity"
  type        = string
  default     = ""
}

variable "user_identity_client_id" {
  description = "The Client ID of the User Managed Identity"
  type        = string
  default     = ""
}

variable "app_insights_id" {
  description = "The Resource ID of the Application Insights used to store Function runtime logs"
  type        = string
  default     = ""
}

variable "app_insights_connection_string" {
  description = "The Connection String for the Application Insights resource used to store Function runtime logs"
  type        = string
  default     = ""
}

variable "app_insights_instrumentation_key" {
  description = "The Instrumentation Key for the Application Insights resource used to store Function runtime logs"
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
  description = "This boolean value will enable the pre-built frontend portal for Labcoat"
  type        = bool
  default     = true
}

variable "frontend_url" {
  description = "The URL of the Frontend Portal"
  type        = string
  default     = ""
}
