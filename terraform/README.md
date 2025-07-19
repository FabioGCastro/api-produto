# Azure API Management for Produto API - Terraform Configuration

This Terraform configuration creates and manages an Azure API Management (APIM) service for the Produto API, including monitoring, security policies, and developer portal configuration.

## Architecture Overview

The configuration deploys the following Azure resources:

- **Resource Group**: Container for all resources
- **API Management Service**: Main APIM instance with developer portal
- **API Definition**: Produto API with OpenAPI 3.0 specification
- **API Version Set**: Version management for the API
- **Backend Configuration**: Connection to your backend service
- **Product**: API product for subscription management
- **Application Insights**: Monitoring and analytics
- **Policies**: CORS, rate limiting, and security policies
- **Diagnostic Settings**: Logging and monitoring configuration

## Prerequisites

1. **Azure CLI** installed and authenticated
2. **Terraform** >= 1.0 installed
3. **Azure Subscription** with appropriate permissions
4. **Backend API** deployed and accessible (your Produto API service)

### Required Azure Permissions

Your account needs the following permissions:
- `Contributor` role on the subscription or resource group
- `API Management Service Contributor` role
- `Application Insights Component Contributor` role

## Quick Start

### 1. Clone and Navigate

```bash
cd terraform
```

### 2. Configure Variables

Copy the example configuration file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

```hcl
# Minimum required configuration
resource_group_name = "rg-your-produto-api"
location           = "East US"
apim_name          = "apim-your-produto-api"
publisher_name     = "Your Company"
publisher_email    = "admin@yourcompany.com"
backend_url        = "https://your-backend-api.azurewebsites.net"
```

### 3. Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```

### 4. Access Your API

After deployment, Terraform will output important URLs and information:

```bash
# View all outputs
terraform output

# Get the API gateway URL
terraform output api_management_gateway_url

# Get developer portal URL
terraform output api_management_developer_portal_url
```

## Configuration Options

### Basic Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `resource_group_name` | Resource group name | `rg-produto-api` | Yes |
| `location` | Azure region | `East US` | Yes |
| `apim_name` | API Management service name | `apim-produto-api` | Yes |
| `publisher_name` | Publisher organization name | `Produto API Team` | Yes |
| `publisher_email` | Publisher email address | `admin@example.com` | Yes |
| `backend_url` | Your API backend URL | - | Yes |

### SKU Options

Choose the appropriate SKU based on your needs:

| SKU | Description | Use Case |
|-----|-------------|----------|
| `Developer_1` | Development/testing | Single developer, no SLA |
| `Basic_1` | Small production | Up to 2 units, 99.95% SLA |
| `Standard_1` | Medium production | Up to 4 units, 99.95% SLA |
| `Premium_1` | Enterprise | Multi-region, VNet support, 99.95% SLA |
| `Consumption_0` | Serverless | Pay-per-call, auto-scaling |

### Security and Policies

Configure security policies in `terraform.tfvars`:

```hcl
api_management_policies = {
  enable_cors              = true
  cors_allowed_origins     = ["https://yourdomain.com"]
  enable_rate_limiting     = true
  rate_limit_calls         = 1000
  rate_limit_renewal_period = 3600
  enable_ip_filtering      = true
  allowed_ips              = ["192.168.1.0/24"]
}
```

### Custom Domain Configuration

To use custom domains, configure SSL certificates:

```hcl
certificate_configuration = {
  enable_custom_domain = true
  gateway_hostname     = "api.yourcompany.com"
  portal_hostname      = "developer.yourcompany.com"
  certificate_path     = "/path/to/certificate.pfx"
  certificate_password = "certificate-password"
}
```

### Virtual Network Integration

For private deployments:

```hcl
virtual_network_configuration = {
  enable_vnet_integration = true
  subnet_id               = "/subscriptions/.../subnets/apim-subnet"
  vnet_type              = "Internal"  # or "External"
}
```

## API Endpoints

After deployment, your API will be available at:

```
https://{apim-name}.azure-api.net/produtos/
```

### Available Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/ready` | Readiness check |
| GET | `/api/produto` | List all products |
| POST | `/api/produto` | Create a product |
| GET | `/api/produto/{id}` | Get product by ID |
| PUT | `/api/produto/{id}` | Update product |
| DELETE | `/api/produto/{id}` | Delete product |

### Example API Calls

```bash
# Health check
curl -X GET 'https://your-apim.azure-api.net/produtos/health' \
  -H 'Ocp-Apim-Subscription-Key: YOUR_SUBSCRIPTION_KEY'

# List products
curl -X GET 'https://your-apim.azure-api.net/produtos/api/produto' \
  -H 'Ocp-Apim-Subscription-Key: YOUR_SUBSCRIPTION_KEY' \
  -H 'Content-Type: application/json'

# Create a product
curl -X POST 'https://your-apim.azure-api.net/produtos/api/produto' \
  -H 'Ocp-Apim-Subscription-Key: YOUR_SUBSCRIPTION_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "nome": "Smartphone",
    "preco": 999.99,
    "categoria": "Eletrônicos"
  }'
```

## Monitoring and Observability

### Application Insights

The configuration automatically creates Application Insights for monitoring:

- **Request tracking**: All API calls are logged
- **Performance metrics**: Response times and throughput
- **Error tracking**: Failed requests and exceptions
- **Custom dashboards**: Available in Azure portal

### Accessing Monitoring Data

1. **Azure Portal**: Navigate to your Application Insights resource
2. **Logs**: Use KQL queries to analyze data
3. **Metrics**: View performance dashboards
4. **Alerts**: Set up automated notifications

### Sample KQL Queries

```kql
// API response times
requests
| where timestamp > ago(1h)
| summarize avg(duration) by bin(timestamp, 5m)
| render timechart

// Error rates
requests
| where timestamp > ago(24h)
| summarize total=count(), errors=countif(success == false) by bin(timestamp, 1h)
| extend errorRate = (errors * 100.0) / total
| render timechart
```

## Security Best Practices

### 1. Subscription Keys

Always use subscription keys for API access:

```bash
# Header-based (recommended)
-H 'Ocp-Apim-Subscription-Key: YOUR_KEY'

# Query parameter (less secure)
?subscription-key=YOUR_KEY
```

### 2. IP Filtering

Restrict access by IP address:

```hcl
api_management_policies = {
  enable_ip_filtering = true
  allowed_ips         = ["203.0.113.0/24", "198.51.100.0/24"]
}
```

### 3. Rate Limiting

Implement rate limiting to prevent abuse:

```hcl
api_management_policies = {
  enable_rate_limiting     = true
  rate_limit_calls         = 1000
  rate_limit_renewal_period = 3600  # 1 hour
}
```

### 4. HTTPS Only

The configuration enforces HTTPS for all API calls.

## Troubleshooting

### Common Issues

#### 1. Backend Connectivity

**Problem**: API Management can't reach your backend
**Solution**: 
- Verify backend URL is accessible
- Check firewall rules
- Ensure backend accepts requests from APIM IP addresses

#### 2. Subscription Key Issues

**Problem**: 401 Unauthorized errors
**Solution**:
- Verify subscription key is correct
- Check if subscription is active
- Ensure key is sent in correct header/query parameter

#### 3. CORS Errors

**Problem**: Browser requests fail with CORS errors
**Solution**:
- Update CORS policy in `terraform.tfvars`
- Add your frontend domain to `cors_allowed_origins`

### Debugging Steps

1. **Check API Management logs**:
   ```bash
   az apim api-diagnostic show --resource-group RG_NAME --service-name APIM_NAME --api-id API_ID --diagnostic-id applicationinsights
   ```

2. **Test backend connectivity**:
   ```bash
   curl -X GET "YOUR_BACKEND_URL/health"
   ```

3. **Verify DNS resolution**:
   ```bash
   nslookup your-apim-name.azure-api.net
   ```

## Cost Optimization

### SKU Selection

- **Development**: Use `Developer_1` (no SLA, lowest cost)
- **Production**: Start with `Basic_1`, scale up as needed
- **Variable workload**: Consider `Consumption_0` for pay-per-call

### Resource Management

```bash
# Check current usage
az apim show --resource-group RG_NAME --name APIM_NAME --query "sku"

# Scale up/down (for non-consumption SKUs)
az apim update --resource-group RG_NAME --name APIM_NAME --sku-name Basic_2
```

## Maintenance

### Updates

To update the infrastructure:

```bash
# Update terraform.tfvars with new values
# Plan the changes
terraform plan

# Apply updates
terraform apply
```

### Backup

Important configurations are stored in Terraform state. Ensure you:

1. **Back up terraform.tfstate** regularly
2. **Use remote state** (Azure Storage, Terraform Cloud)
3. **Version control** your .tf files

### Disaster Recovery

For production environments:

1. **Multi-region deployment**: Deploy APIM in multiple regions
2. **Backup policies**: Export API definitions regularly
3. **Documentation**: Keep runbooks updated

## Clean Up

To destroy all resources:

```bash
terraform destroy
```

⚠️ **Warning**: This will permanently delete all resources and data.

## Support and Contributing

### Getting Help

1. **Azure Documentation**: [API Management Documentation](https://docs.microsoft.com/en-us/azure/api-management/)
2. **Terraform Provider**: [AzureRM Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
3. **Issues**: Create an issue in this repository

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Changelog

### v1.0.0
- Initial release
- Basic API Management configuration
- Application Insights integration
- CORS and security policies
- Developer portal setup