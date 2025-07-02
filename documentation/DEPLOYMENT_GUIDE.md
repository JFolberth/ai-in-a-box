# Deployment Guide

This guide provides comprehensive information about deploying the [Azure AI Foundry](https://learn.microsoft.com/en-us/azure/ai-foundry/) SPA project across different scenarios and environments.

## 🎯 Deployment Overview

The Azure AI Foundry SPA supports multiple deployment patterns:

1. **Infrastructure + Code** - Complete greenfield deployment
2. **Code-Only** - Deploy application code to existing infrastructure (recommended for [Azure Deployment Environments](https://learn.microsoft.com/en-us/azure/deployment-environments/))
3. **Local Development** - Run application locally for development and testing

## 🏗️ Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Deployment Workflow                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Infrastructure Deployment          Code Deployment             │
│  ┌─────────────────────────────┐   ┌─────────────────────────────┐ │
│  │                             │   │                             │ │
│  │  Option A: [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/)+[Azure Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)  │   │  Backend: deploy-backend-func-code.ps1│ │
│  │  Option B: ADE Portal       │   │  Frontend: deploy-frontend- │ │
│  │  Option C: CI/CD Pipeline   │   │           spa-code.ps1          │ │
│  │                             │   │                             │ │
│  └─────────────────────────────┘   └─────────────────────────────┘ │
│              │                                   │                 │
│              └───────────────┬───────────────────┘                 │
│                              │                                     │
│                   ┌─────────────────────────────┐                  │
│                   │     Running Application     │                  │
│                   │  Frontend + Backend + AI    │                  │
│                   └─────────────────────────────┘                  │
└─────────────────────────────────────────────────────────────────┘
```

## 📋 Deployment Scripts Overview

The Azure AI Foundry SPA includes **two focused deployment scripts** for code-only deployment to existing [Azure](https://learn.microsoft.com/en-us/azure/) infrastructure. These scripts are designed for Azure Deployment Environments (ADE), CI/CD pipelines, and scenarios where infrastructure is already provisioned.

> **📝 Script Naming**: The scripts are named to clearly indicate their purpose:
> - `deploy-backend-func-code.ps1` - Deploys **[Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/) code** only
> - `deploy-frontend-spa-code.ps1` - Deploys **SPA (Single Page Application) code** only

### `deploy-backend-func-code.ps1` - Backend Code-Only Deployment

**Purpose**: Deploy C# Azure Functions application code to an existing Azure Functions app

**Use Cases**:
- ✅ After ADE infrastructure deployment
- ✅ CI/CD pipeline code deployments  
- ✅ Development iterations on existing infrastructure
- ✅ Hotfixes and patches to running applications

**Requirements**:
- Existing [Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/) app (infrastructure already deployed)
- Existing Resource Group
- Azure CLI authentication
- [.NET 8 SDK](https://learn.microsoft.com/en-us/dotnet/core/whats-new/dotnet-8)

**Parameters**:
- `FunctionAppName` (required) - Name of the Azure Functions app
- `ResourceGroupName` (required) - Name of the resource group
- `SkipBuild` (optional) - Skip the dotnet build step
- `SkipTest` (optional) - Skip endpoint testing after deployment

**Example**:
```powershell
./deploy-scripts/deploy-backend-func-code.ps1 `
    -FunctionAppName "func-ai-foundry-spa-backend-dev-eus2" `
    -ResourceGroupName "rg-ai-foundry-spa-backend-dev-eus2"
```

**What it does**:
1. ✅ Validates Azure CLI authentication
2. ✅ Verifies Azure Functions app exists in specified resource group
3. ✅ Builds .NET Azure Functions app (unless `-SkipBuild`)
4. ✅ Creates deployment package (ZIP)
5. ✅ Deploys code to Azure Functions app
6. ✅ Tests health endpoint (unless `-SkipTest`)
7. ✅ Provides deployment summary with URLs

### `deploy-frontend-spa-code.ps1` - Frontend Code-Only Deployment

**Purpose**: Deploy JavaScript SPA application code to an existing [Azure Static Web Apps](https://learn.microsoft.com/en-us/azure/static-web-apps/)

**Use Cases**:
- ✅ After ADE infrastructure deployment
- ✅ CI/CD pipeline code deployments
- ✅ Frontend updates and UI changes
- ✅ Environment-specific configuration deployment

**Requirements**:
- Existing Azure Static Web Apps (infrastructure already deployed)
- Existing Resource Group  
- Azure CLI authentication
- [Node.js](https://learn.microsoft.com/en-us/windows/dev-environment/javascript/nodejs-overview) 20+ and npm

**Parameters**:
- `StaticWebAppName` (required) - Name of the Azure Static Web Apps
- `ResourceGroupName` (required) - Name of the resource group
- `BackendUrl` (optional) - Backend Azure Functions URL for environment configuration
- `SkipBuild` (optional) - Skip the npm build step

**Example**:
```powershell
./deploy-scripts/deploy-frontend-spa-code.ps1 `
    -StaticWebAppName "stapp-aibox-fd-dev-eus2" `
    -ResourceGroupName "rg-ai-foundry-spa-frontend-dev-eus2" `
    -BackendUrl "https://func-ai-foundry-spa-backend-dev-eus2.azurewebsites.net/api"
```

**What it does**:
1. ✅ Validates Azure CLI authentication
2. ✅ Verifies Azure Static Web Apps exists in specified resource group
3. ✅ Creates DEV environment configuration with Azure AI Foundry settings
4. ✅ Installs npm dependencies and builds frontend (unless `-SkipBuild`)
5. ✅ Installs [SWA CLI](https://learn.microsoft.com/en-us/azure/static-web-apps/static-web-apps-cli-overview) if needed
6. ✅ Deploys to Azure Static Web Apps using SWA CLI
7. ✅ Provides deployment summary with URLs

## 🎯 Key Design Principles

### Code-Only Focus
- **No Infrastructure Deployment**: Scripts assume Azure resources already exist
- **No Local Development Logic**: Scripts are Azure-only (use `npm run dev` and `func start` for local development)
- **No Resource Discovery**: All resource names must be explicitly provided as parameters
- **No Default Assumptions**: No default resource names or auto-detection logic

### Infrastructure Separation
- **Infrastructure First**: Deploy infrastructure through ADE, Azure Bicep, or CI/CD pipelines
- **Code Second**: Use these scripts to deploy application code to existing resources
- **Clear Boundaries**: Scripts focus solely on application deployment, not infrastructure management

## 🚀 Deployment Scenarios

### ✅ When to Use These Scripts

- **After ADE Infrastructure Deployment**: Perfect for code deployment after ADE creates infrastructure
- **CI/CD Pipeline Integration**: Ideal for automated code deployment in DevOps workflows
- **Development Iterations**: When making code changes to existing applications
- **Environment Updates**: Deploying new configurations or features to running applications
- **Hotfixes and Patches**: Quick code updates without infrastructure changes

### ❌ When NOT to Use These Scripts

- **Infrastructure Deployment**: Use ADE portal, Azure Bicep templates, or CI/CD pipelines for infrastructure
- **Local Development**: Use `npm run dev` and `func start` for local development and testing
- **First-Time Setup**: Deploy infrastructure first through ADE or Azure Bicep before using these scripts
- **Resource Creation**: Scripts cannot create Azure resources; they only deploy code to existing resources

### Scenario 1: [Azure Deployment Environments (ADE)](https://learn.microsoft.com/en-us/azure/deployment-environments/) - Recommended

Perfect for enterprise environments with governance and self-service requirements.

#### Step 1: Deploy Infrastructure via ADE
1. Navigate to Azure Deployment Environments portal
2. Select your project and catalog
3. Choose frontend/backend environment definitions
4. Fill in required parameters
5. Deploy through ADE portal

#### Step 2: Discover Resource Names
```powershell
# Method 1: Check ADE environment "Resources" tab in portal

# Method 2: Use Azure CLI
az functionapp list --query "[?contains(name, 'func-ai-foundry-spa-backend')].{name:name,resourceGroup:resourceGroup,state:state}" --output table
az staticwebapp list --query "[?contains(name, 'stapp-aibox-fd')].{name:name,resourceGroup:resourceGroup,defaultHostname:defaultHostname}" --output table
```

#### Step 3: Deploy Application Code
```powershell
# Deploy backend code
./deploy-scripts/deploy-backend-func-code.ps1 `
    -FunctionAppName "func-ai-foundry-spa-backend-dev-eus2" `
    -ResourceGroupName "rg-ai-foundry-spa-backend-dev-eus2"

# Deploy frontend code
./deploy-scripts/deploy-frontend-spa-code.ps1 `
    -StaticWebAppName "stapp-aibox-fd-dev-eus2" `
    -ResourceGroupName "rg-ai-foundry-spa-frontend-dev-eus2" `
    -BackendUrl "https://func-ai-foundry-spa-backend-dev-eus2.azurewebsites.net/api"
```

#### Step 4: Verify Deployment
```powershell
# Test Function App endpoints
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "https://func-ai-foundry-spa-backend-dev-eus2.azurewebsites.net"

# Access frontend application (URL provided in deployment output)
```

### Scenario 2: Direct [Azure Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/) Deployment

For development environments or when ADE is not available.

#### Step 1: Deploy Infrastructure
```powershell
# Deploy complete infrastructure
az deployment sub create `
    --template-file infra/main-orchestrator.bicep `
    --parameters infra/dev-orchestrator.parameters.bicepparam `
    --location eastus2
```

#### Step 2: Deploy Application Code
Use the same code deployment steps as ADE scenario.

### Scenario 3: CI/CD Pipeline Deployment

For automated deployment in DevOps pipelines.

#### Automated [GitHub Actions](https://learn.microsoft.com/en-us/azure/developer/github/github-actions) (Current Implementation)

The project includes a **fully automated CI/CD pipeline** that deploys both infrastructure and application code on main branch pushes:

```yaml
# .github/workflows/ci.yml
on:
  push:
    branches: [main]

jobs:
  # 1. Build and validate
  bicep-validation: # Validates infrastructure templates
  frontend-build:   # Builds JavaScript SPA
  backend-build:    # Builds .NET Azure Functions
  
  # 2. Deploy infrastructure
  deploy-dev-infrastructure:
    needs: [bicep-validation]
    uses: ./.github/workflows/shared-infrastructure-deploy.yml
    
  # 3. Deploy application code automatically
  deploy-backend-code:
    needs: [backend-build, deploy-dev-infrastructure]
    # Uses deploy-backend-func-code.ps1 with infrastructure outputs
    
  deploy-frontend-code:
    needs: [frontend-build, deploy-dev-infrastructure, deploy-backend-code]
    # Uses deploy-frontend-spa-code.ps1 with infrastructure outputs
```

**✅ Fully Automated Features:**
- **Infrastructure deployment** via Azure CLI + Azure Bicep
- **Backend code deployment** via existing [PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/overview) script
- **Frontend code deployment** via existing PowerShell script
- **Resource discovery** from infrastructure outputs
- **Dependency management** (infrastructure → backend → frontend)
- **Error handling** and deployment status reporting

**🎯 Automatic Deployment Flow:**
1. **Push to main branch** triggers the workflow
2. **Infrastructure** is deployed to Azure via Azure Bicep templates
3. **Backend Azure Functions code** is deployed automatically using resource names from infrastructure
4. **Frontend Azure Static Web Apps code** is deployed automatically with backend integration
5. **Complete application** is ready and accessible

#### Manual GitHub Actions Example (For Reference)

For manual deployments or other environments, you can use a simpler workflow pattern:

```yaml
name: Manual Deploy AI Foundry SPA

on:
  workflow_dispatch:
    inputs:
      function_app_name:
        description: 'Function App Name'
        required: true
      frontend_rg_name:
        description: 'Frontend Resource Group Name'  
        required: true

jobs:
  deploy-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Azure Login
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      - name: Deploy Backend
        run: |
          ./deploy-scripts/deploy-backend-func-code.ps1 \
            -FunctionAppName "${{ github.event.inputs.function_app_name }}" \
            -ResourceGroupName "${{ github.event.inputs.backend_rg_name }}"
        shell: pwsh

  deploy-frontend:
    needs: deploy-backend
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Azure Login
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Deploy Frontend
        run: |
          ./deploy-scripts/deploy-frontend-spa-code.ps1 \
            -StaticWebAppName "${{ github.event.inputs.static_web_app_name }}" \
            -ResourceGroupName "${{ github.event.inputs.frontend_rg_name }}" \
            -BackendUrl "${{ github.event.inputs.backend_url }}"
        shell: pwsh
```

#### Automated ADE Testing (Built-in CI)

The repository includes automated ADE frontend deployment testing that runs on every push to the `main` branch. This provides continuous validation of the ADE integration.

**How it works:**
1. **Triggered automatically** on main branch pushes after successful builds and validation
2. **Creates ADE environment** using `az devcenter dev environment create`
3. **Deploys frontend code** to the ADE-created Static Web App
4. **Reports deployment status** in the CI summary
5. **Cleans up automatically** to avoid resource accumulation

**ADE Configuration Used:**
```bash
# DevCenter Configuration
DevCenter: "devecnter-eus-dev"
Project: "ai-foundry"  
Catalog: "ai-in-abox-infrastructure"
Environment Definition: "AI_Foundry_SPA_Frontend"
Environment Type: "dev"

# Parameters file: infra/environments/frontend/ade.parameters.json
{
  "applicationName": { "value": "aibox" },
  "logAnalyticsWorkspaceName": { "value": "la-logging-dev-eus" },
  "logAnalyticsResourceGroupName": { "value": "rg-logging-dev-eus" },
  "adeName": { "value": "cicd-fd" },
  "devCenterProjectName": { "value": "ai-foundry" }
}
```

**Benefits:**
- ✅ **Continuous Testing**: Every main branch change tests ADE deployment
- ✅ **Early Detection**: Catches ADE configuration issues before manual deployment
- ✅ **Zero Maintenance**: Fully automated with cleanup
- ✅ **Real Environment**: Tests against actual ADE infrastructure, not mocks

**Monitoring:**
- Check GitHub Actions CI logs for ADE deployment status
- Failed ADE deployments will fail the entire CI pipeline
- Deployment URLs and resource names are logged in CI summary

## 🔍 Resource Discovery Methods

When working with existing infrastructure, use these methods to find resource names:

### Azure Portal
1. Navigate to Resource Groups
2. Filter by naming patterns (e.g., "ai-foundry-spa")
3. Note Function App and Static Web App names

### Azure CLI Commands
```powershell
# Search by resource type and naming pattern
az resource list --resource-type "Microsoft.Web/sites" --query "[?kind=='functionapp' && contains(name, 'ai-foundry-spa-backend')].{name:name,resourceGroup:resourceGroup}" --output table

az resource list --resource-type "Microsoft.Web/staticSites" --query "[?contains(name, 'stapp-aibox-fd')].{name:name,resourceGroup:resourceGroup}" --output table

# List all resources in a specific resource group
az resource list --resource-group "rg-ai-foundry-spa-*" --query "[].{name:name,type:type}" --output table
```

### PowerShell Resource Discovery Script
```powershell
# Save as: Get-AzureResources.ps1
param(
    [string]$NamePattern = "ai-foundry-spa"
)

Write-Host "🔍 Discovering AI Foundry SPA resources..." -ForegroundColor Yellow

$functionApps = az functionapp list --query "[?contains(name, '$NamePattern-backend')].{name:name,resourceGroup:resourceGroup,state:state}" | ConvertFrom-Json
$staticWebApps = az staticwebapp list --query "[?contains(name, 'stapp-aibox-fd')].{name:name,resourceGroup:resourceGroup,defaultHostname:defaultHostname}" | ConvertFrom-Json

Write-Host "📱 Function Apps:" -ForegroundColor Cyan
$functionApps | Format-Table -AutoSize

Write-Host "🌐 Static Web Apps:" -ForegroundColor Cyan  
$staticWebApps | Format-Table -AutoSize

if ($functionApps -and $staticWebApps) {
    Write-Host "💡 Example deployment commands:" -ForegroundColor Green
    Write-Host "Backend:" -ForegroundColor Yellow
    Write-Host "  ./deploy-scripts/deploy-backend-func-code.ps1 -FunctionAppName '$($functionApps[0].name)' -ResourceGroupName '$($functionApps[0].resourceGroup)'" -ForegroundColor White
    Write-Host "Frontend:" -ForegroundColor Yellow
    Write-Host "  ./deploy-scripts/deploy-frontend-spa-code.ps1 -StaticWebAppName '$($staticWebApps[0].name)' -ResourceGroupName '$($staticWebApps[0].resourceGroup)'" -ForegroundColor White
}
```

## 🛠️ Local Development

For local development, use the appropriate development tools instead of deployment scripts:

### Frontend Development
```bash
cd src/frontend
npm install
npm run dev    # Starts dev server with hot reload at http://localhost:5173
```

### Backend Development
```bash
cd src/backend
func start     # Starts Function App at http://localhost:7071
```

### VS Code Tasks
Use predefined VS Code tasks for streamlined development:
1. "Start Azurite" - Required for Function App local storage
2. "🔧 Manual Start Function App" - Builds and starts Function App
3. "AI Foundry SPA: Build and Run" - Starts frontend development server

## ⚠️ Important Notes

### Script Limitations and Design
- **Code-Only Deployment**: Scripts only deploy application code, not infrastructure
- **Existing Resources Required**: All Azure resources must exist before running scripts
- **No Auto-Discovery**: Resource names must be explicitly provided (no default assumptions)
- **Azure-Only**: No local development mode; use VS Code tasks for local development

### Security Considerations
- Both scripts require Azure CLI authentication
- Function App uses system-assigned managed identity for AI Foundry access
- No secrets are stored in configuration files
- CORS policies restrict access to authorized origins

### Environment Configuration
- Frontend script includes hardcoded DEV environment AI Foundry settings
- Backend URL can be configured via parameter for environment-specific deployments
- Local development uses different endpoints than production

### Troubleshooting
- **Authentication Errors**: Run `az login` to authenticate with Azure
- **Resource Not Found**: Verify resource names and resource group names are correct
- **Build Failures**: Ensure Node.js 20+ and .NET 8 SDK are installed
- **Permission Errors**: Verify Azure account has appropriate permissions on target resources
- **Infrastructure Missing**: Deploy infrastructure through ADE or Bicep before using these scripts

## 📚 Related Documentation

- [Development Guide](DEVELOPMENT.md) - Local development setup and workflows
- [Azure Deployment Environments Guide](AZURE_DEPLOYMENT_ENVIRONMENTS.md) - ADE-specific implementation
- [Infrastructure Guide](INFRASTRUCTURE.md) - Architecture and resource details
- [Configuration Guide](CONFIGURATION.md) - Environment variables and settings
- [Setup Guide](SETUP.md) - Initial project setup instructions

---

For questions or issues, refer to the specific documentation guides or check the troubleshooting sections in each file.
