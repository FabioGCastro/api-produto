variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-produto-api"
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "East US"
  validation {
    condition = contains([
      "East US", "East US 2", "West US", "West US 2", "West US 3",
      "Central US", "North Central US", "South Central US",
      "West Central US", "Canada Central", "Canada East",
      "Brazil South", "North Europe", "West Europe", "UK South",
      "UK West", "France Central", "Germany West Central",
      "Switzerland North", "Norway East", "Southeast Asia",
      "East Asia", "Australia East", "Australia Southeast",
      "Japan East", "Japan West", "Korea Central", "India Central",
      "South Africa North"
    ], var.location)
    error_message = "The location must be a valid Azure region."
  }
}

variable "apim_name" {
  description = "Name of the API Management service"
  type        = string
  default     = "apim-produto-api"
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,48}[a-zA-Z0-9]$", var.apim_name))
    error_message = "API Management name must be between 1 and 50 characters, start with a letter, and contain only letters, numbers, and hyphens."
  }
}

variable "publisher_name" {
  description = "Publisher name for API Management"
  type        = string
  default     = "Produto API Team"
}

variable "publisher_email" {
  description = "Publisher email for API Management"
  type        = string
  default     = "admin@example.com"
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.publisher_email))
    error_message = "Publisher email must be a valid email address."
  }
}

variable "sku_name" {
  description = "SKU name for API Management service"
  type        = string
  default     = "Developer_1"
  validation {
    condition = contains([
      "Developer_1", "Basic_1", "Basic_2", "Standard_1", "Standard_2",
      "Premium_1", "Premium_2", "Premium_4", "Premium_8", "Consumption_0"
    ], var.sku_name)
    error_message = "SKU name must be one of: Developer_1, Basic_1, Basic_2, Standard_1, Standard_2, Premium_1, Premium_2, Premium_4, Premium_8, Consumption_0."
  }
}

variable "backend_url" {
  description = "Backend URL for the Produto API"
  type        = string
  default     = "https://your-produto-api.azurecontainer.io"
  validation {
    condition     = can(regex("^https?://", var.backend_url))
    error_message = "Backend URL must be a valid HTTP or HTTPS URL."
  }
}

variable "backend_api_key" {
  description = "API key for backend authentication (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "Produto API"
    Owner       = "DevOps Team"
    CreatedBy   = "Terraform"
  }
}

variable "enable_application_insights" {
  description = "Enable Application Insights for monitoring"
  type        = bool
  default     = true
}

variable "api_management_policies" {
  description = "Custom policies for API Management"
  type = object({
    enable_cors              = bool
    cors_allowed_origins     = list(string)
    enable_rate_limiting     = bool
    rate_limit_calls         = number
    rate_limit_renewal_period = number
    enable_ip_filtering      = bool
    allowed_ips              = list(string)
  })
  default = {
    enable_cors              = true
    cors_allowed_origins     = ["*"]
    enable_rate_limiting     = false
    rate_limit_calls         = 100
    rate_limit_renewal_period = 60
    enable_ip_filtering      = false
    allowed_ips              = []
  }
}

variable "subscription_key_header_name" {
  description = "Custom header name for subscription key"
  type        = string
  default     = "Ocp-Apim-Subscription-Key"
}

variable "subscription_key_query_name" {
  description = "Custom query parameter name for subscription key"
  type        = string
  default     = "subscription-key"
}

variable "api_version" {
  description = "API version"
  type        = string
  default     = "v2"
}

variable "api_path" {
  description = "API path prefix"
  type        = string
  default     = "produtos"
}

variable "enable_developer_portal" {
  description = "Enable the developer portal"
  type        = bool
  default     = true
}

variable "certificate_configuration" {
  description = "SSL certificate configuration for custom domains"
  type = object({
    enable_custom_domain = bool
    gateway_hostname     = string
    portal_hostname      = string
    certificate_path     = string
    certificate_password = string
  })
  default = {
    enable_custom_domain = false
    gateway_hostname     = ""
    portal_hostname      = ""
    certificate_path     = ""
    certificate_password = ""
  }
  sensitive = true
}

variable "notification_sender_email" {
  description = "Email address for API Management notifications"
  type        = string
  default     = null
  validation {
    condition = var.notification_sender_email == null || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.notification_sender_email))
    error_message = "Notification sender email must be a valid email address or null."
  }
}

variable "virtual_network_configuration" {
  description = "Virtual network configuration for API Management"
  type = object({
    enable_vnet_integration = bool
    subnet_id               = string
    vnet_type              = string
  })
  default = {
    enable_vnet_integration = false
    subnet_id               = ""
    vnet_type              = "None"
  }
  validation {
    condition = contains(["None", "External", "Internal"], var.virtual_network_configuration.vnet_type)
    error_message = "VNet type must be one of: None, External, Internal."
  }
}