# AGENTS.md - Infrastructure

This directory contains Azure Bicep templates for deploying the AI Foundry SPA infrastructure using Azure Verified Modules (AVM).

## Architecture Overview

- **Multi-resource group deployment**: Frontend and backend resources are separated
- **Main orchestrator**: `main-orchestrator.bicep` deploys all components
- **Environment-based**: Uses parameter files for different environments (dev, staging, prod)
- **Azure Verified Modules**: Leverages Microsoft's AVM for best practices and security

## Key Files

- `main-orchestrator.bicep`: Main Bicep template that orchestrates all deployments
- `dev-orchestrator.parameters.bicepparam`: Parameter file for development environment
- `modules/`: Custom Bicep modules for specific components
- `environments/`: Azure Deployment Environment (ADE) configurations

## Deployment Commands

### Validate Bicep Templates
```bash
# Validate main orchestrator
az deployment sub validate --template-file main-orchestrator.bicep --parameters dev-orchestrator.parameters.bicepparam --location eastus2

# Validate all modules
az bicep build --file main-orchestrator.bicep
```

### Deploy Infrastructure
```bash
# Deploy to development environment
az deployment sub create --template-file main-orchestrator.bicep --parameters dev-orchestrator.parameters.bicepparam --location eastus2 --name "ai-foundry-spa-dev-$(date +%Y%m%d-%H%M%S)"
```

### Resource Validation
```bash
# Check deployment status
az deployment sub show --name <deployment-name>

# List created resources
az resource list --tag Environment=dev --tag Project="AI Foundry SPA"
```

## Bicep Best Practices

### Security Requirements
- **Managed Identity**: All resources must use system-assigned managed identities
- **RBAC**: Follow principle of least privilege
- **Secure strings**: Use `@secure()` decorator for sensitive parameters
- **Key Vault integration**: Store secrets in Azure Key Vault, reference in templates

### Naming Conventions
- Follow Azure naming conventions with environment prefixes
- Use consistent resource abbreviations: `func-`, `st-`, `law-`, `appi-`
- Include environment and location in resource names
- Example: `func-ai-foundry-spa-backend-dev-eus2`

### Resource Organization
- Tag all resources with `Environment`, `Project`, and `CostCenter`
- Use resource groups to separate concerns (frontend vs backend)
- Implement proper dependency management between resources
- Use outputs to pass data between modules

## Module Development

### Creating New Modules
```bicep
// Template structure for new modules
@description('Description of the module purpose')
param parameterName string

@allowed(['dev', 'staging', 'prod'])
param environment string

// Resource definition with proper naming
resource resourceName 'Microsoft.ResourceType/resourceName@2023-XX-XX' = {
  name: 'prefix-${parameterName}-${environment}-${location}'
  location: location
  // ... configuration
}

@description('Output description')
output outputName string = resourceName.properties.someValue
```

### Module Testing
- Use `az deployment group validate` to test modules
- Implement What-If deployments before actual deployment
- Test with different parameter combinations
- Validate outputs are properly exposed

## Azure Verified Modules (AVM)

### Preferred AVM Modules
- `avm/res/web/site` for Function Apps and Static Web Apps
- `avm/res/operational-insights/workspace` for Log Analytics
- `avm/res/insights/component` for Application Insights
- `avm/res/cognitive-services/account` for AI Foundry integration

### AVM Integration Patterns
```bicep
// Example AVM module usage
module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.4.0' = {
  name: 'logAnalyticsWorkspace'
  params: {
    name: workspaceName
    location: location
    skuName: 'PerGB2018'
    dataRetention: 30
    // ... other parameters
  }
}
```

## Troubleshooting

### Common Issues
- **Quota limits**: Check Azure subscription quotas before deployment
- **Region availability**: Verify all services are available in target region
- **Naming conflicts**: Ensure globally unique names for storage accounts and function apps
- **Permission issues**: Verify deployment principal has Contributor access

### Debugging Commands
```bash
# Check deployment errors
az deployment sub show --name <deployment-name> --query "properties.error"

# List failed deployments
az deployment sub list --filter "provisioningState eq 'Failed'"

# Get detailed error information
az monitor activity-log list --resource-group <rg-name> --max-events 50
```

## CI/CD Integration

### Required Environment Variables
- `AZURE_CLIENT_ID`: Service principal client ID
- `AZURE_TENANT_ID`: Azure tenant ID
- `AZURE_SUBSCRIPTION_ID`: Target subscription ID
- `AZURE_CLIENT_SECRET`: Service principal secret (stored in GitHub Secrets)

### Pipeline Integration
- Bicep templates are validated on all PRs
- Infrastructure deployment happens on main branch merges
- Use deployment slots for zero-downtime updates where applicable

## Performance Considerations

### Resource Sizing
- Function App: Consumption plan for cost optimization
- Storage Account: Standard LRS for non-critical data
- Application Insights: Basic tier for development environments
- AI Foundry: Choose appropriate SKU based on expected load

### Monitoring Setup
- Enable diagnostic settings on all resources
- Configure alerts for critical metrics
- Use Log Analytics workspace for centralized logging
- Implement custom metrics for business-specific monitoring