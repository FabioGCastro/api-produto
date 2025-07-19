output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the created resource group"
  value       = azurerm_resource_group.main.location
}

output "api_management_name" {
  description = "Name of the API Management service"
  value       = azurerm_api_management.main.name
}

output "api_management_id" {
  description = "ID of the API Management service"
  value       = azurerm_api_management.main.id
}

output "api_management_gateway_url" {
  description = "Gateway URL of the API Management service"
  value       = azurerm_api_management.main.gateway_url
}

output "api_management_developer_portal_url" {
  description = "Developer portal URL of the API Management service"
  value       = azurerm_api_management.main.developer_portal_url
}

output "api_management_management_api_url" {
  description = "Management API URL of the API Management service"
  value       = azurerm_api_management.main.management_api_url
}

output "api_management_portal_url" {
  description = "Publisher portal URL of the API Management service"
  value       = azurerm_api_management.main.portal_url
}

output "api_management_scm_url" {
  description = "SCM URL of the API Management service"
  value       = azurerm_api_management.main.scm_url
}

output "produto_api_name" {
  description = "Name of the Produto API"
  value       = azurerm_api_management_api.produto_api.name
}

output "produto_api_id" {
  description = "ID of the Produto API"
  value       = azurerm_api_management_api.produto_api.id
}

output "produto_api_path" {
  description = "Path of the Produto API"
  value       = azurerm_api_management_api.produto_api.path
}

output "produto_api_full_url" {
  description = "Full URL to access the Produto API"
  value       = "${azurerm_api_management.main.gateway_url}/${azurerm_api_management_api.produto_api.path}"
}

output "produto_api_endpoints" {
  description = "Available endpoints for the Produto API"
  value = {
    health_check     = "${azurerm_api_management.main.gateway_url}/${azurerm_api_management_api.produto_api.path}/health"
    readiness_check  = "${azurerm_api_management.main.gateway_url}/${azurerm_api_management_api.produto_api.path}/ready"
    list_products    = "${azurerm_api_management.main.gateway_url}/${azurerm_api_management_api.produto_api.path}/api/produto"
    product_by_id    = "${azurerm_api_management.main.gateway_url}/${azurerm_api_management_api.produto_api.path}/api/produto/{id}"
  }
}

output "produto_product_id" {
  description = "ID of the Produto product in API Management"
  value       = azurerm_api_management_product.produto_product.product_id
}

output "produto_product_display_name" {
  description = "Display name of the Produto product"
  value       = azurerm_api_management_product.produto_product.display_name
}

output "backend_url" {
  description = "Backend URL configured for the API"
  value       = var.backend_url
  sensitive   = true
}

output "application_insights_name" {
  description = "Name of the Application Insights instance"
  value       = var.enable_application_insights ? azurerm_application_insights.main.name : null
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = var.enable_application_insights ? azurerm_application_insights.main.instrumentation_key : null
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = var.enable_application_insights ? azurerm_application_insights.main.connection_string : null
  sensitive   = true
}

output "api_management_public_ip_addresses" {
  description = "Public IP addresses of the API Management service"
  value       = azurerm_api_management.main.public_ip_addresses
}

output "api_management_private_ip_addresses" {
  description = "Private IP addresses of the API Management service"
  value       = azurerm_api_management.main.private_ip_addresses
}

output "api_management_identity" {
  description = "System-assigned managed identity of the API Management service"
  value = {
    principal_id = azurerm_api_management.main.identity[0].principal_id
    tenant_id    = azurerm_api_management.main.identity[0].tenant_id
    type         = azurerm_api_management.main.identity[0].type
  }
}

output "subscription_key_header_name" {
  description = "Header name for subscription key"
  value       = var.subscription_key_header_name
}

output "subscription_key_query_name" {
  description = "Query parameter name for subscription key"
  value       = var.subscription_key_query_name
}

output "curl_examples" {
  description = "Example curl commands to test the API"
  value = {
    health_check = "curl -X GET '${azurerm_api_management.main.gateway_url}/${azurerm_api_management_api.produto_api.path}/health' -H '${var.subscription_key_header_name}: YOUR_SUBSCRIPTION_KEY'"
    list_products = "curl -X GET '${azurerm_api_management.main.gateway_url}/${azurerm_api_management_api.produto_api.path}/api/produto' -H '${var.subscription_key_header_name}: YOUR_SUBSCRIPTION_KEY' -H 'Content-Type: application/json'"
    create_product = "curl -X POST '${azurerm_api_management.main.gateway_url}/${azurerm_api_management_api.produto_api.path}/api/produto' -H '${var.subscription_key_header_name}: YOUR_SUBSCRIPTION_KEY' -H 'Content-Type: application/json' -d '{\"nome\":\"Test Product\",\"preco\":100.0,\"categoria\":\"Test Category\"}'"
  }
}

output "swagger_ui_url" {
  description = "URL to access the Swagger UI documentation"
  value       = "${azurerm_api_management.main.developer_portal_url}/apis/${azurerm_api_management_api.produto_api.name}"
}

output "deployment_summary" {
  description = "Summary of the deployed resources"
  value = {
    resource_group       = azurerm_resource_group.main.name
    location            = azurerm_resource_group.main.location
    api_management      = azurerm_api_management.main.name
    api_name           = azurerm_api_management_api.produto_api.name
    product_name       = azurerm_api_management_product.produto_product.display_name
    gateway_url        = azurerm_api_management.main.gateway_url
    developer_portal   = azurerm_api_management.main.developer_portal_url
    monitoring_enabled = var.enable_application_insights
    sku                = var.sku_name
  }
}