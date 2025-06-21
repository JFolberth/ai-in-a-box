# AI Foundry SPA - Multi-Resource Group Architecture

## Overview

The infrastructure has been restructured to deploy the frontend and backend components to separate Azure resource groups, each with their own dedicated Application Insights instance for better isolation and monitoring. The architecture includes cross-resource group RBAC for secure AI Foundry access.

## Architecture Components

### Frontend Resource Group
- **Name Pattern**: `rg-ai-foundry-spa-frontend-{environmentName}-{resourceToken}`
- **Resources**:
  - Storage Account for static website hosting (`staifrontspa{resourceToken}`)
  - Application Insights for frontend monitoring
- **Purpose**: Hosts the JavaScript SPA with public mode access

### Backend Resource Group  
- **Name Pattern**: `rg-ai-foundry-spa-backend-{environmentName}-{resourceToken}`
- **Resources**:
  - Function App for AI Foundry proxy (`func-ai-foundry-spa-backend-{environmentName}-{resourceToken}`)
  - Storage Account for Function App runtime (`stfnbackspa{resourceToken}`)
  - App Service Plan (Consumption)
  - Application Insights for backend monitoring
- **Purpose**: Hosts the C# Azure Function that proxies AI Foundry requests with managed identity

### Cross-Resource Group RBAC
- **Function App Identity**: System-assigned managed identity
- **AI Foundry Access**: Azure AI Developer role scoped to specific AI Foundry resource
- **Least Privilege**: No overly broad permissions like Contributor or Owner

## File Structure

```
infra/
├── main-orchestrator.bicep              # Main orchestrator (subscription scope)
├── dev-orchestrator.parameters.bicepparam # Parameters for orchestrator
└── modules/
    ├── frontend.bicep                   # Frontend resources module
    ├── backend.bicep                    # Backend resources module
    └── rbac.bicep                       # Cross-resource group RBAC module
```

## Deployment Process

### Using Azure CLI (Recommended)
```bash
# Deploy infrastructure
az deployment sub create \
  --location eastus \
  --template-file infra/main-orchestrator.bicep \
  --parameters infra/dev-orchestrator.parameters.bicepparam

# Deploy Function App
cd src/backend
func azure functionapp publish func-ai-foundry-spa-backend-dev-001

# Deploy Frontend
cd ../frontend
npm run build:dev
az storage blob upload-batch \
  --destination '$web' \
  --source ./dist \
  --account-name staifrontspa001 \
  --auth-mode login
```

### Using PowerShell Script
```powershell
../deploy-scripts/deploy.ps1  # Uses default parameters from bicepparam file
```

## Key Changes from Previous Architecture

1. **Separate Resource Groups**: Frontend and backend are now isolated
2. **Dedicated Application Insights**: Each component has its own monitoring instance
3. **Subscription-Level Deployment**: Uses `az deployment sub create` instead of resource group deployment
4. **Orchestrator Pattern**: Main template orchestrates deployment to multiple resource groups
5. **Modular Design**: Frontend and backend modules can be deployed independently
6. **Cross-RG RBAC**: Dedicated RBAC module manages permissions across resource groups
7. **Public Mode**: No authentication requirements, Function App uses managed identity for AI Foundry access
8. **Security Best Practices**: Least privilege RBAC, no hardcoded subscription IDs (uses `subscription()` function)

## Resource Naming Conventions

### Frontend Resources
- Storage Account: `staifrontspa{resourceToken}` (e.g., `staifrontspa001`)
- Application Insights: `appi-ai-foundry-spa-frontend-{environmentName}-{resourceToken}`

### Backend Resources
- Function App: `func-ai-foundry-spa-backend-{environmentName}-{resourceToken}` (e.g., `func-ai-foundry-spa-backend-dev-001`)
- Function Storage: `stfnbackspa{resourceToken}` (e.g., `stfnbackspa001`)
- App Service Plan: `asp-ai-foundry-spa-backend-{environmentName}-{resourceToken}`
- Application Insights: `appi-ai-foundry-spa-backend-{environmentName}-{resourceToken}`

## Deployment Outputs

The orchestrator provides the following outputs:

- `frontendResourceGroupName`: Name of the frontend resource group
- `backendResourceGroupName`: Name of the backend resource group
- `frontendStorageAccountName`: Frontend storage account name
- `frontendStaticWebsiteUrl`: Frontend website URL
- `frontendApplicationInsightsConnectionString`: Frontend monitoring connection string
- `backendFunctionAppName`: Backend Function App name
- `backendFunctionAppUrl`: Backend Function App URL
- `backendApiUrl`: Backend API endpoint URL
- `backendApplicationInsightsConnectionString`: Backend monitoring connection string
- `frontendEnvironmentVariables`: Complete environment configuration for frontend

## Benefits

1. **Isolation**: Frontend and backend failures don't affect each other's monitoring
2. **Scalability**: Each component can be scaled independently
3. **Security**: Different RBAC can be applied to frontend vs backend resources
4. **Cost Management**: Better cost tracking per component
5. **Maintenance**: Easier to update or replace individual components
6. **Public Access**: No authentication barriers while maintaining secure backend AI access
7. **Compliance**: Least privilege access patterns for AI Foundry integration

## Monitoring Strategy

- **Frontend Monitoring**: Track user interactions, page loads, errors in frontend Application Insights
- **Backend Monitoring**: Track AI Foundry API calls, performance, errors in backend Application Insights
- **Consolidated Logging**: Both components use the same Log Analytics Workspace for centralized log aggregation

## Next Steps

1. Test the deployment using Azure CLI or PowerShell script
2. Verify both Application Insights instances are receiving telemetry
3. Validate AI Foundry RBAC permissions are working correctly
4. Test frontend-to-backend communication through Function App proxy
5. Verify static website hosting and CORS configuration
6. Consider implementing alerts and dashboards for each component
