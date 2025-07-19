# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

# Create Azure API Management service
resource "azurerm_api_management" "main" {
  name                = var.apim_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name

  tags = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# Create API in API Management
resource "azurerm_api_management_api" "produto_api" {
  name                = "produto-api"
  resource_group_name = azurerm_resource_group.main.name
  api_management_name = azurerm_api_management.main.name
  revision            = "1"
  display_name        = "Produto API"
  path                = "produtos"
  protocols           = ["https", "http"]
  description         = "API de Cadastro de Produtos - Terraform Managed"
  version             = "v2"
  version_set_id      = azurerm_api_management_api_version_set.produto_api_version_set.id

  import {
    content_format = "openapi+json"
    content_value = jsonencode({
      openapi = "3.0.0"
      info = {
        title       = "Produto API"
        description = "API de Cadastro de Produtos - Nova Versão"
        version     = "2.0.0"
        contact = {
          email = var.publisher_email
        }
      }
      servers = [
        {
          url = var.backend_url
        }
      ]
      paths = {
        "/health" = {
          get = {
            summary     = "Health Check"
            description = "Verificação se a aplicação está saudável"
            responses = {
              "200" = {
                description = "Status saudável"
              }
              "500" = {
                description = "Status não saudável"
              }
            }
          }
        }
        "/ready" = {
          get = {
            summary     = "Readiness Check"
            description = "Verificação se a aplicação está pronta"
            responses = {
              "200" = {
                description = "Status pronto"
              }
              "500" = {
                description = "Status não pronto"
              }
            }
          }
        }
        "/api/produto" = {
          get = {
            summary     = "List all products"
            description = "Listagem de todos os produtos"
            responses = {
              "200" = {
                description = "Resultado da busca"
                content = {
                  "application/json" = {
                    schema = {
                      type = "array"
                      items = {
                        "$ref" = "#/components/schemas/Produto"
                      }
                    }
                  }
                }
              }
              "400" = {
                description = "bad input parameter"
              }
            }
          }
          post = {
            summary     = "Create a product"
            description = "Cadastro de um produto"
            requestBody = {
              required = true
              content = {
                "application/json" = {
                  schema = {
                    "$ref" = "#/components/schemas/Produto"
                  }
                }
              }
            }
            responses = {
              "200" = {
                description = "OK"
              }
            }
          }
        }
        "/api/produto/{id}" = {
          get = {
            summary     = "Get a product by ID"
            description = "Listagem de um produto"
            parameters = [
              {
                name        = "id"
                in          = "path"
                description = "Id do produto"
                required    = true
                schema = {
                  type = "string"
                }
              }
            ]
            responses = {
              "200" = {
                description = "Resultado da busca"
                content = {
                  "application/json" = {
                    schema = {
                      "$ref" = "#/components/schemas/Produto"
                    }
                  }
                }
              }
              "400" = {
                description = "bad input parameter"
              }
            }
          }
          put = {
            summary     = "Update a product"
            description = "Atualização de um produto"
            parameters = [
              {
                name        = "id"
                in          = "path"
                description = "Id do produto"
                required    = true
                schema = {
                  type = "string"
                }
              }
            ]
            requestBody = {
              required = true
              content = {
                "application/json" = {
                  schema = {
                    "$ref" = "#/components/schemas/Produto"
                  }
                }
              }
            }
            responses = {
              "200" = {
                description = "OK"
              }
            }
          }
          delete = {
            summary     = "Delete a product"
            description = "Exclusão de um produto"
            parameters = [
              {
                name        = "id"
                in          = "path"
                description = "Id do produto"
                required    = true
                schema = {
                  type = "string"
                }
              }
            ]
            responses = {
              "204" = {
                description = "OK"
              }
              "400" = {
                description = "Produto inválido"
              }
              "404" = {
                description = "Produto não encontrado"
              }
            }
          }
        }
      }
      components = {
        schemas = {
          Produto = {
            type     = "object"
            required = ["categoria", "nome", "preco"]
            properties = {
              id = {
                type    = "string"
                format  = "uuid"
                example = "d290f1ee-6c54-4b01-90e6-d701748f0851"
              }
              nome = {
                type    = "string"
                example = "Geladeira"
              }
              preco = {
                type    = "number"
                example = 500.0
              }
              categoria = {
                type    = "string"
                example = "Eletrodomésticos"
              }
            }
          }
        }
      }
    })
  }
}

# Create API Version Set
resource "azurerm_api_management_api_version_set" "produto_api_version_set" {
  name                = "produto-api-version-set"
  resource_group_name = azurerm_resource_group.main.name
  api_management_name = azurerm_api_management.main.name
  display_name        = "Produto API Version Set"
  versioning_scheme   = "Segment"
}

# Create Backend
resource "azurerm_api_management_backend" "produto_backend" {
  name                = "produto-backend"
  resource_group_name = azurerm_resource_group.main.name
  api_management_name = azurerm_api_management.main.name
  protocol            = "http"
  url                 = var.backend_url
  description         = "Produto API Backend"

  credentials {
    header = {
      "x-api-key" = var.backend_api_key
    }
  }
}

# Create Product
resource "azurerm_api_management_product" "produto_product" {
  product_id            = "produto-product"
  api_management_name   = azurerm_api_management.main.name
  resource_group_name   = azurerm_resource_group.main.name
  display_name          = "Produto Product"
  subscription_required = true
  approval_required     = false
  published             = true
  description           = "Product for Produto API access"
}

# Associate API with Product
resource "azurerm_api_management_product_api" "produto_product_api" {
  api_name            = azurerm_api_management_api.produto_api.name
  product_id          = azurerm_api_management_product.produto_product.product_id
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
}

# Create API Management Policy for CORS
resource "azurerm_api_management_api_policy" "produto_api_policy" {
  api_name            = azurerm_api_management_api.produto_api.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name

  xml_content = <<XML
<policies>
  <inbound>
    <base />
    <cors allow-credentials="false">
      <allowed-origins>
        <origin>*</origin>
      </allowed-origins>
      <allowed-methods>
        <method>GET</method>
        <method>POST</method>
        <method>PUT</method>
        <method>DELETE</method>
        <method>OPTIONS</method>
      </allowed-methods>
      <allowed-headers>
        <header>*</header>
      </allowed-headers>
    </cors>
    <set-backend-service base-url="${var.backend_url}" />
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
XML
}

# Create Named Values for configuration
resource "azurerm_api_management_named_value" "backend_url" {
  name                = "backend-url"
  resource_group_name = azurerm_resource_group.main.name
  api_management_name = azurerm_api_management.main.name
  display_name        = "Backend URL"
  value               = var.backend_url
}

# Create Application Insights for monitoring
resource "azurerm_application_insights" "main" {
  name                = "${var.apim_name}-insights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"

  tags = var.tags
}

# Create API Management Logger
resource "azurerm_api_management_logger" "main" {
  name                = "appinsights-logger"
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  resource_id         = azurerm_application_insights.main.id

  application_insights {
    instrumentation_key = azurerm_application_insights.main.instrumentation_key
  }
}

# Create diagnostic settings for API
resource "azurerm_api_management_api_diagnostic" "produto_api_diagnostic" {
  identifier               = "applicationinsights"
  resource_group_name      = azurerm_resource_group.main.name
  api_management_name      = azurerm_api_management.main.name
  api_name                 = azurerm_api_management_api.produto_api.name
  api_management_logger_id = azurerm_api_management_logger.main.id

  sampling_percentage       = 100.0
  always_log_errors         = true
  log_client_ip             = true
  verbosity                 = "information"
  http_correlation_protocol = "W3C"

  frontend_request {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "accept",
      "origin",
    ]
  }

  frontend_response {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "content-length",
      "origin",
    ]
  }

  backend_request {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "accept",
      "origin",
    ]
  }

  backend_response {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "content-length",
      "origin",
    ]
  }
}