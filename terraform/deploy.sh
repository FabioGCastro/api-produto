#!/bin/bash

# Azure API Management Terraform Deployment Script
# This script automates the deployment of Azure API Management infrastructure

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is not installed or not in PATH"
        return 1
    fi
    return 0
}

# Function to check Azure login status
check_azure_login() {
    if ! az account show &> /dev/null; then
        print_error "Not logged in to Azure. Please run 'az login' first."
        return 1
    fi
    return 0
}

# Function to validate terraform.tfvars
validate_tfvars() {
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Creating from example..."
        if [ -f "terraform.tfvars.example" ]; then
            cp terraform.tfvars.example terraform.tfvars
            print_warning "Please edit terraform.tfvars with your specific values before continuing."
            read -p "Press Enter to continue after editing terraform.tfvars..."
        else
            print_error "terraform.tfvars.example not found. Cannot create terraform.tfvars."
            return 1
        fi
    fi
    
    # Check for required variables
    required_vars=("resource_group_name" "location" "apim_name" "publisher_email" "backend_url")
    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}[[:space:]]*=" terraform.tfvars; then
            print_error "Required variable '${var}' not found in terraform.tfvars"
            return 1
        fi
    done
    
    return 0
}

# Function to display deployment summary
show_deployment_summary() {
    print_status "Deployment Summary:"
    echo "==================="
    
    if [ -f "terraform.tfvars" ]; then
        echo "Resource Group: $(grep '^resource_group_name' terraform.tfvars | cut -d'"' -f2)"
        echo "Location: $(grep '^location' terraform.tfvars | cut -d'"' -f2)"
        echo "APIM Name: $(grep '^apim_name' terraform.tfvars | cut -d'"' -f2)"
        echo "Backend URL: $(grep '^backend_url' terraform.tfvars | cut -d'"' -f2)"
    fi
    echo "==================="
}

# Function to run terraform commands with error handling
run_terraform() {
    local command=$1
    local description=$2
    
    print_status "$description"
    
    case $command in
        "init")
            if ! terraform init; then
                print_error "Terraform init failed"
                return 1
            fi
            ;;
        "validate")
            if ! terraform validate; then
                print_error "Terraform validation failed"
                return 1
            fi
            ;;
        "plan")
            if ! terraform plan -out=tfplan; then
                print_error "Terraform plan failed"
                return 1
            fi
            ;;
        "apply")
            if ! terraform apply tfplan; then
                print_error "Terraform apply failed"
                return 1
            fi
            ;;
        "destroy")
            if ! terraform destroy; then
                print_error "Terraform destroy failed"
                return 1
            fi
            ;;
    esac
    
    return 0
}

# Function to display post-deployment information
show_post_deployment_info() {
    print_success "Deployment completed successfully!"
    echo
    print_status "Getting deployment outputs..."
    
    # Get important outputs
    gateway_url=$(terraform output -raw api_management_gateway_url 2>/dev/null || echo "N/A")
    portal_url=$(terraform output -raw api_management_developer_portal_url 2>/dev/null || echo "N/A")
    api_url=$(terraform output -raw produto_api_full_url 2>/dev/null || echo "N/A")
    
    echo
    echo "========================================="
    echo "           DEPLOYMENT COMPLETE          "
    echo "========================================="
    echo "Gateway URL: $gateway_url"
    echo "Developer Portal: $portal_url"
    echo "API URL: $api_url"
    echo "========================================="
    echo
    
    print_status "Next steps:"
    echo "1. Access the developer portal to create subscriptions"
    echo "2. Test your API endpoints using the provided URLs"
    echo "3. Configure custom domains if needed"
    echo "4. Set up monitoring alerts in Application Insights"
    echo
    
    # Show example curl commands
    print_status "Example API test commands:"
    echo "# Health check (replace YOUR_SUBSCRIPTION_KEY):"
    echo "curl -X GET '$api_url/health' -H 'Ocp-Apim-Subscription-Key: YOUR_SUBSCRIPTION_KEY'"
    echo
    echo "# List products:"
    echo "curl -X GET '$api_url/api/produto' -H 'Ocp-Apim-Subscription-Key: YOUR_SUBSCRIPTION_KEY'"
    echo
}

# Function to cleanup temporary files
cleanup() {
    print_status "Cleaning up temporary files..."
    rm -f tfplan
}

# Main deployment function
deploy() {
    print_status "Starting Azure API Management deployment..."
    
    # Pre-deployment checks
    print_status "Running pre-deployment checks..."
    
    check_command "terraform" || exit 1
    check_command "az" || exit 1
    check_azure_login || exit 1
    validate_tfvars || exit 1
    
    print_success "All pre-deployment checks passed!"
    
    # Show deployment summary
    show_deployment_summary
    
    # Confirm deployment
    echo
    read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Deployment cancelled by user."
        exit 0
    fi
    
    # Run Terraform commands
    run_terraform "init" "Initializing Terraform..." || exit 1
    run_terraform "validate" "Validating Terraform configuration..." || exit 1
    run_terraform "plan" "Creating deployment plan..." || exit 1
    
    echo
    print_warning "Review the plan above. This will create Azure resources that may incur costs."
    read -p "Do you want to apply this plan? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Deployment cancelled by user."
        cleanup
        exit 0
    fi
    
    run_terraform "apply" "Applying Terraform configuration..." || exit 1
    
    # Post-deployment
    show_post_deployment_info
    cleanup
}

# Function to destroy infrastructure
destroy() {
    print_warning "This will PERMANENTLY DELETE all Azure resources created by this Terraform configuration!"
    echo
    read -p "Are you sure you want to destroy the infrastructure? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Destroy cancelled by user."
        exit 0
    fi
    
    echo
    read -p "Type 'DELETE' to confirm destruction: " confirm
    if [ "$confirm" != "DELETE" ]; then
        print_warning "Destroy cancelled - confirmation text did not match."
        exit 0
    fi
    
    run_terraform "destroy" "Destroying infrastructure..." || exit 1
    print_success "Infrastructure destroyed successfully!"
    cleanup
}

# Function to show help
show_help() {
    echo "Azure API Management Terraform Deployment Script"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  deploy    Deploy the Azure API Management infrastructure (default)"
    echo "  destroy   Destroy the Azure API Management infrastructure"
    echo "  plan      Show the deployment plan without applying"
    echo "  validate  Validate the Terraform configuration"
    echo "  help      Show this help message"
    echo
    echo "Prerequisites:"
    echo "  - Azure CLI installed and logged in"
    echo "  - Terraform installed"
    echo "  - terraform.tfvars configured with your values"
    echo
    echo "Examples:"
    echo "  $0              # Deploy infrastructure"
    echo "  $0 deploy       # Deploy infrastructure"
    echo "  $0 plan         # Show deployment plan"
    echo "  $0 destroy      # Destroy infrastructure"
}

# Main script logic
case "${1:-deploy}" in
    "deploy")
        deploy
        ;;
    "destroy")
        destroy
        ;;
    "plan")
        check_command "terraform" || exit 1
        validate_tfvars || exit 1
        run_terraform "init" "Initializing Terraform..." || exit 1
        run_terraform "plan" "Creating deployment plan..." || exit 1
        ;;
    "validate")
        check_command "terraform" || exit 1
        run_terraform "init" "Initializing Terraform..." || exit 1
        run_terraform "validate" "Validating Terraform configuration..." || exit 1
        print_success "Terraform configuration is valid!"
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo
        show_help
        exit 1
        ;;
esac