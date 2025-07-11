# Deployment Guide

*Comprehensive guide for deploying the Azure AI Foundry SPA across different scenarios and environments.*

## 🎯 Deployment Overview

The Azure AI Foundry SPA supports multiple deployment patterns to meet different organizational needs:

1. **Quick Start Script** - Complete greenfield deployment (infrastructure + code)
2. **Manual Azure CLI** - Full deployment with parameter customization
3. **Azure Deployment Environments (ADE)** - Enterprise self-service deployment
4. **GitHub Actions CI/CD** - Automated deployment pipeline
5. **Code-Only Deployment** - Deploy application code to existing infrastructure

## 🏗️ Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Deployment Workflow                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Infrastructure Deployment          Code Deployment             │
│  ┌─────────────────────────────┐   ┌─────────────────────────────┐ │
│  │                             │   │                             │ │
│  │  Option A: Azure CLI+Bicep  │   │  Backend: deploy-backend-   │ │
│  │  Option B: ADE Portal       │   │          func-code.ps1      │ │
│  │  Option C: CI/CD Pipeline   │   │  Frontend: deploy-frontend- │ │
│  │  Option D: Quick Start      │   │           spa-code.ps1      │ │
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

## 🚀 Deployment Options

### 1. **Quick Start Script** (Recommended for getting started)
- **Best for**: Learning, development, testing, first deployment
- **Effort**: ~15 minutes automated deployment
- **Skills needed**: Basic PowerShell, Azure CLI
- **Features**: Interactive prompts, greenfield/brownfield support
- **⚠️ Important**: Uses defaults from `main-orchestrator.bicep`, NOT `.bicepparam` files

### 2. **Azure Deployment Environments (ADE)** (Recommended for enterprise)
- **Best for**: Enterprise teams, standardized deployments, governance
- **Effort**: ~1 hour for initial setup, then 15 minutes per deployment
- **Skills needed**: Azure portal navigation, ADE concepts
- **Features**: Self-service portal, approval workflows, cost tracking
- **Uses**: `.bicepparam` parameter files for configuration

### 3. **Manual Azure CLI Deployment**
- **Best for**: Custom scenarios, advanced configuration
- **Effort**: ~30 minutes for first deployment
- **Skills needed**: Azure CLI, Bicep templates
- **Features**: Full parameter control, scripting support
- **Uses**: `.bicepparam` parameter files for configuration

### 4. **GitHub Actions CI/CD** (Automated)
- **Best for**: Teams with ongoing development, production systems
- **Effort**: ~2 hours for pipeline setup, then automatic
- **Skills needed**: GitHub Actions, CI/CD concepts
- **Features**: Automated testing, multi-environment deployment
- **Uses**: `.bicepparam` parameter files for configuration

### 5. **Code-Only Deployment** (Existing infrastructure)
- **Best for**: Updates to existing deployments, ADE follow-up
- **Effort**: ~5-10 minutes per deployment
- **Skills needed**: PowerShell, Azure CLI
- **Features**: Fast updates, no infrastructure changes

## 📋 Parameter Configuration

**Understanding Configuration Options:**

The AI Foundry SPA uses different configuration approaches depending on your deployment method:

- **Quick Start Script** (`deploy-quickstart.ps1`): Uses interactive prompts and defaults from `main-orchestrator.bicep`. Does NOT use `.bicepparam` files.

- **All Other Methods** (ADE, CI/CD, Manual): Use `.bicepparam` parameter files for configuration. These files override the defaults in `main-orchestrator.bicep`.

**Configuration Priority:**
1. Quick Start Script: Interactive prompts → `main-orchestrator.bicep` defaults
2. Other Methods: `.bicepparam` files → `main-orchestrator.bicep` defaults

### Deployment Mode Options

The deployment supports two modes:

- **Greenfield**: Creates all Azure resources from scratch
- **Brownfield**: Uses existing Azure AI Foundry and/or Log Analytics resources

## 📱 Code-Only Deployment Scripts

The project includes **two focused deployment scripts** for code-only deployment to existing Azure infrastructure. These scripts are designed for Azure Deployment Environments (ADE), CI/CD pipelines, and scenarios where infrastructure is already provisioned.

### `deploy-backend-func-code.ps1` - Backend Code Deployment

**Purpose**: Deploy C# Azure Functions application code to an existing Azure Functions app

**Use Cases**:
- ✅ After ADE infrastructure deployment
- ✅ CI/CD pipeline code deployments  
- ✅ Development iterations on existing infrastructure
- ✅ Hotfixes and patches to running applications

**Requirements**:
- Existing Azure Functions app (infrastructure already deployed)
- Existing Resource Group
- Azure CLI authentication
- .NET 8 SDK

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

### `deploy-frontend-spa-code.ps1` - Frontend Code Deployment

**Purpose**: Deploy JavaScript SPA application code to an existing Azure Static Web Apps

**Use Cases**:
- ✅ After ADE infrastructure deployment
- ✅ CI/CD pipeline code deployments
- ✅ Frontend updates and UI changes
- ✅ Environment-specific configuration deployment

**Requirements**:
- Existing Azure Static Web Apps (infrastructure already deployed)
- Existing Resource Group  
- Azure CLI authentication
- Node.js 20+ and npm

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

## 🌍 Supported Azure Regions

The AI Foundry SPA can be deployed to **27 Azure regions** where Cognitive Services (AIServices) are available:

```
australiaeast       brazilsouth        canadacentral      canadaeast
eastus              eastus2            francecentral      germanywestcentral
italynorth          japaneast          koreacentral       northcentralus
norwayeast          polandcentral      southafricanorth   southcentralus
southeastasia       southindia         spaincentral       swedencentral
switzerlandnorth    switzerlandwest    uaenorth          uksouth
westeurope          westus             westus3
```

**Region Validation**: The `deploy-quickstart.ps1` script validates region availability before deployment.

## 🔧 Method 1: Quick Start Script (Recommended for getting started)

### Prerequisites
- Azure CLI installed and logged in
- PowerShell Core installed
- Azure subscription with Contributor permissions
- Git repository cloned locally

### Usage
```powershell
# Navigate to project directory
cd /path/to/ai-in-a-box

# Run quick start deployment with interactive prompts
./deploy-scripts/deploy-quickstart.ps1

# Or with specific parameters to bypass prompts
./deploy-scripts/deploy-quickstart.ps1 -Location "eastus2" -ApplicationName "myapp" -InteractiveMode:$false
```

### Key Features
- **Interactive Prompts**: Guides you through configuration choices
- **Greenfield/Brownfield Support**: Choose to create new resources or use existing ones
- **Automatic Agent Deployment**: Includes AI agent creation and configuration
- **Validation**: Checks prerequisites and region availability
- **Error Handling**: Clear error messages and troubleshooting guidance

**⚠️ Important Notes:**
- Uses defaults from `main-orchestrator.bicep`, NOT parameter files
- Designed for development, learning, and first deployments
- For production deployments, consider ADE or CI/CD methods

## 🏢 Method 2: Azure Deployment Environments (ADE) (Recommended for enterprise)

### Prerequisites
- Azure DevCenter configured
- ADE project access
- ADE catalog with AI Foundry SPA definitions

### Step 1: Access ADE Portal

1. **Navigate to Azure Portal** → Azure Deployment Environments
2. **Select your DevCenter** and project
3. **Browse the catalog** for "AI Foundry SPA" definitions

### Step 2: Create Environment

1. **Click "Create Environment"**
2. **Select Environment Type**: "AI Foundry SPA Frontend" or "Backend"
3. **Configure Parameters**:
   ```yaml
   # Environment parameters
   aiFoundryEndpoint: "https://your-ai-foundry.cognitiveservices.azure.com/"
   aiFoundryDeployment: "gpt-4"
   aiFoundryAgentName: "AI in A Box"
   environmentName: "prod"
   location: "eastus2"
   ```
4. **Review and Create**

### Step 3: Deploy Application Code

Once ADE creates the infrastructure, use the code-only deployment scripts:

```powershell
# Discover resource names from ADE
az functionapp list --query "[?contains(name, 'func-ai-foundry-spa-backend')].{name:name,resourceGroup:resourceGroup,state:state}" --output table
az staticwebapp list --query "[?contains(name, 'stapp-aibox-fd')].{name:name,resourceGroup:resourceGroup,defaultHostname:defaultHostname}" --output table

# Deploy backend code
./deploy-scripts/deploy-backend-func-code.ps1 `
  -FunctionAppName "func-ai-foundry-spa-backend-prod-xyz" `
  -ResourceGroupName "rg-ai-foundry-spa-backend-prod-eus2"

# Deploy frontend code  
./deploy-scripts/deploy-frontend-spa-code.ps1 `
  -StaticWebAppName "stapp-ai-foundry-spa-frontend-prod-xyz" `
  -ResourceGroupName "rg-ai-foundry-spa-frontend-prod-eus2"
```

### Step 4: Verify Deployment
```powershell
# Test Function App endpoints
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "https://func-ai-foundry-spa-backend-prod-xyz.azurewebsites.net"

# Access frontend application (URL provided in deployment output)
```

## 🔧 Method 3: Manual Azure CLI Deployment

### Prerequisites
- Azure CLI installed and logged in
- Azure subscription with Contributor permissions
- **EXISTING Azure AI Foundry resource** (cannot be created by orchestrator due to circular dependencies)
- AI Foundry resource details: endpoint URL, resource group, resource name, project name
- Git repository cloned locally

### Step 1: Prepare Configuration

```bash
# Navigate to project directory
cd /path/to/ai-in-a-box

# Copy and edit parameters file
cp infra/dev-orchestrator.parameters.bicepparam infra/prod-orchestrator.parameters.bicepparam
```

**Edit your parameters file:**
```bicep
using 'main-orchestrator.bicep'

// Deployment Mode: Choose greenfield (create everything) or brownfield (use existing)
param createAiFoundryResourceGroup = false  // Set to true for greenfield
param createLogAnalyticsWorkspace = false   // Set to true for greenfield

// For Brownfield (using existing AI Foundry): Provide existing resource details
param aiFoundryResourceGroupName = 'rg-your-ai-foundry'
param aiFoundryResourceName = 'your-ai-foundry-resource'
param aiFoundryProjectName = 'firstProject'
param aiFoundryEndpoint = 'https://your-production-ai-foundry.cognitiveservices.azure.com/'
param aiFoundryModelDeploymentName = 'gpt-4.1-mini'
param aiFoundryAgentName = 'AI in A Box'

// For Brownfield (using existing Log Analytics): Provide existing resource details
param logAnalyticsResourceGroupName = 'rg-your-logging'
param logAnalyticsWorkspaceName = 'your-log-analytics-workspace'

// Required: Your user principal ID
param userPrincipalId = 'your-user-principal-id'

// Environment settings  
param environmentName = 'prod'
param location = 'eastus2'
param applicationName = 'ai-foundry-spa'

// Optional: Custom domain for production
param customDomainName = 'ai.yourcompany.com'  // Optional
```

> 💡 **Tip**: For production environments using centralized AI Foundry or Log Analytics, set the corresponding `create*` parameters to `false` and provide the existing resource details.

### Step 2: Deploy Infrastructure

```bash
# Deploy complete infrastructure
az deployment sub create \
  --name "ai-foundry-spa-production-$(date +%Y%m%d-%H%M%S)" \
  --template-file "infra/main-orchestrator.bicep" \
  --parameters "infra/prod-orchestrator.parameters.bicepparam" \
  --location "eastus2"

# Monitor deployment progress
az deployment sub show \
  --name "ai-foundry-spa-production-$(date +%Y%m%d-%H%M%S)" \
  --query "{status: properties.provisioningState, timestamp: properties.timestamp}"
```

### Step 3: Deploy Application Code

**Backend Deployment:**
```bash
# Build and package backend
cd src/backend
dotnet restore
dotnet publish -c Release -o publish

# Create deployment package
cd publish
zip -r ../backend-deployment.zip .
cd ..

# Get Function App details
FUNCTION_APP_NAME=$(az functionapp list --query "[?contains(name, 'ai-foundry-spa-backend')].name" -o tsv | head -1)
FUNCTION_RG=$(az functionapp list --query "[?contains(name, 'ai-foundry-spa-backend')].resourceGroup" -o tsv | head -1)

# Deploy to Azure Functions
az functionapp deployment source config-zip \
  --resource-group "$FUNCTION_RG" \
  --name "$FUNCTION_APP_NAME" \
  --src "backend-deployment.zip"

cd ../..
```

**Frontend Deployment:**
```bash
# Build frontend
cd src/frontend
npm install
npm run build

# Get Static Web App details
STATIC_APP_NAME=$(az staticwebapp list --query "[?contains(name, 'ai-foundry-spa-frontend')].name" -o tsv | head -1)
STATIC_RG=$(az staticwebapp list --query "[?contains(name, 'ai-foundry-spa-frontend')].resourceGroup" -o tsv | head -1)

# Note: Static Web App deployment varies by configuration
# For GitHub integration, push to main branch triggers deployment
# For manual deployment, use Azure Portal or Azure DevOps
echo "Frontend built. Use Azure Portal to deploy dist/ folder to Static Web App: $STATIC_APP_NAME"

cd ../..
```

### Step 4: Verify Deployment

```bash
# Get application URLs
FRONTEND_URL=$(az staticwebapp show --name "$STATIC_APP_NAME" --resource-group "$STATIC_RG" --query "defaultHostname" -o tsv)
BACKEND_URL=$(az functionapp show --name "$FUNCTION_APP_NAME" --resource-group "$FUNCTION_RG" --query "defaultHostName" -o tsv)

echo "🎉 Deployment Complete!"
echo "Frontend: https://$FRONTEND_URL"
echo "Backend: https://$BACKEND_URL"
echo "Health Check: https://$BACKEND_URL/api/health"

# Test health endpoint
curl "https://$BACKEND_URL/api/health" | jq .
```

## 🔄 Method 4: GitHub Actions CI/CD

### Prerequisites
- GitHub repository with the code
- Azure service principal configured
- GitHub secrets configured

### Automatic CI/CD Pipeline (Current Implementation)

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

### Configure GitHub Secrets

Required secrets in your GitHub repository:

```yaml
# In GitHub Settings → Secrets and variables → Actions
AZURE_CREDENTIALS: |
  {
    "clientId": "your-service-principal-client-id",
    "clientSecret": "your-service-principal-secret",
    "subscriptionId": "your-subscription-id",
    "tenantId": "your-tenant-id"
  }

AI_FOUNDRY_ENDPOINT: "https://your-ai-foundry.cognitiveservices.azure.com/"
AI_FOUNDRY_DEPLOYMENT: "gpt-4"
AI_FOUNDRY_AGENT_NAME: "AI in A Box"
USER_PRINCIPAL_ID: "your-user-principal-id"
```

### Enable GitHub Actions

1. **Push to main branch** triggers automatic deployment
2. **Review workflow** in GitHub Actions tab
3. **Monitor deployment** progress in real-time

### Automated ADE Testing

The repository includes automated ADE frontend deployment testing that runs on every push to the `main` branch:

**How it works:**
1. **Triggered automatically** on main branch pushes after successful builds
2. **Creates ADE environment** using `az devcenter dev environment create`
3. **Deploys frontend code** to the ADE-created Static Web App
4. **Reports deployment status** in the CI summary
5. **Cleans up automatically** to avoid resource accumulation

## 🔁 Method 5: Code-Only Deployment

For updates to existing infrastructure:

### Backend Code Updates

```powershell
# Deploy backend code only
./deploy-scripts/deploy-backend-func-code.ps1 `
  -FunctionAppName "your-function-app-name" `
  -ResourceGroupName "your-resource-group-name" `
  -Verbose

# Example output:
# ✅ Backend deployment complete
# Function App: func-ai-foundry-spa-backend-prod-xyz
# Health Check: https://func-ai-foundry-spa-backend-prod-xyz.azurewebsites.net/api/health
```

### Frontend Code Updates

```powershell
# Deploy frontend code only
./deploy-scripts/deploy-frontend-spa-code.ps1 `
  -StaticWebAppName "your-static-app-name" `
  -ResourceGroupName "your-resource-group-name" `
  -BackendUrl "https://your-function-app.azurewebsites.net" `
  -Verbose

# Example output:
# ✅ Frontend deployment complete  
# Static Web App: stapp-ai-foundry-spa-frontend-prod-xyz
# URL: https://stapp-ai-foundry-spa-frontend-prod-xyz.azurestaticapps.net
```

## 🌍 Multi-Environment Deployment

### Environment Strategy

**Development Environment:**
- **Purpose**: Feature development, testing
- **Configuration**: Shared AI Foundry, minimal monitoring
- **Deployment**: Manual or feature branch triggers

**Staging Environment:**
- **Purpose**: Pre-production testing, validation
- **Configuration**: Production-like, separate AI Foundry
- **Deployment**: Develop branch triggers

**Production Environment:**
- **Purpose**: Live user traffic
- **Configuration**: High availability, premium features
- **Deployment**: Main branch triggers, manual approval

### Environment Configuration

**Development (`infra/dev-orchestrator.parameters.bicepparam`):**
```bicep
param environmentName = 'dev'
param skuName = 'F1'  // Free tier
param enableAdvancedSecurity = false
param logRetentionDays = 30
```

**Staging (`infra/staging-orchestrator.parameters.bicepparam`):**
```bicep
param environmentName = 'staging'
param skuName = 'S1'  // Standard tier
param enableAdvancedSecurity = true
param logRetentionDays = 90
```

**Production (`infra/prod-orchestrator.parameters.bicepparam`):**
```bicep
param environmentName = 'prod'
param skuName = 'P1V2'  // Premium tier
param enableAdvancedSecurity = true
param logRetentionDays = 365
param customDomainName = 'ai.yourcompany.com'
```

### Deployment Pipeline

```yaml
# Complete multi-environment pipeline
stages:
  - name: Build
    jobs:
      - job: BuildAndTest
        steps:
          - task: NodeJS
          - task: DotNetCoreCLI
          - task: RunTests
          
  - name: DeployDev
    condition: eq(variables['Build.SourceBranch'], 'refs/heads/develop')
    jobs:
      - deployment: DeployTodev
        environment: 'dev'
        
  - name: DeployStaging
    condition: eq(variables['Build.SourceBranch'], 'refs/heads/main')
    jobs:
      - deployment: DeployToStaging
        environment: 'staging'
        
  - name: DeployProduction
    condition: and(eq(variables['Build.SourceBranch'], 'refs/heads/main'), eq(variables['Build.Reason'], 'Manual'))
    jobs:
      - deployment: DeployToProduction
        environment: 'production'
```

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

## 🚨 Troubleshooting Deployment

### Common Deployment Issues

**1. Resource Name Conflicts**
```bash
# Check for existing resources
az resource list --name "*ai-foundry-spa*" --output table

# Solution: Use different names or clean up existing resources
```

**2. Permission Errors**
```bash
# Verify permissions
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) --all

# Required: Contributor or Owner role
```

**3. Function App Deployment Failures**
```bash
# Check deployment logs
az functionapp log deployment list \
  --name "$FUNCTION_APP_NAME" \
  --resource-group "$FUNCTION_RG"

# Common fix: Verify .azurefunctions directory in package
```

**4. Static Web App Build Issues**
```bash
# Check build configuration
cat .github/workflows/azure-static-web-apps-*.yml

# Verify build settings in Azure Portal
```

### Validation Scripts

**Complete Deployment Test:**
```bash
#!/bin/bash
# deployment-test.sh

echo "Testing AI Foundry SPA deployment..."

# Test backend health
BACKEND_RESPONSE=$(curl -s "https://$BACKEND_URL/api/health")
if [[ $BACKEND_RESPONSE == *"Healthy"* ]]; then
    echo "✅ Backend health check passed"
else
    echo "❌ Backend health check failed"
    exit 1
fi

# Test frontend
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$FRONTEND_URL")
if [[ $FRONTEND_STATUS == "200" ]]; then
    echo "✅ Frontend accessibility check passed"
else
    echo "❌ Frontend accessibility check failed"
    exit 1
fi

# Test AI integration
AI_RESPONSE=$(curl -s -X POST "https://$BACKEND_URL/api/chat" \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello, can you respond?"}')
  
if [[ $AI_RESPONSE == *"message"* ]]; then
    echo "✅ AI integration test passed"
else
    echo "❌ AI integration test failed"
    exit 1
fi

echo "🎉 All deployment tests passed!"
```

## 📊 Post-Deployment Checklist

### Immediate Verification (< 5 minutes)
- [ ] Frontend URL loads successfully
- [ ] Backend health endpoint returns "Healthy"
- [ ] AI chat functionality works end-to-end
- [ ] No errors in browser console
- [ ] Application Insights receiving telemetry

### Security Verification (< 10 minutes)
- [ ] HTTPS enforced on all endpoints
- [ ] CORS configured correctly
- [ ] Managed identity has minimal required permissions
- [ ] No secrets stored in configuration
- [ ] Access logs enabled

### Performance Verification (< 15 minutes)
- [ ] Frontend loads in < 2 seconds
- [ ] API responses in < 5 seconds
- [ ] AI responses in < 10 seconds
- [ ] No memory leaks or resource issues
- [ ] Auto-scaling configured

### Production Readiness (< 30 minutes)
- [ ] Custom domain configured (if applicable)
- [ ] SSL certificates valid
- [ ] Monitoring alerts configured
- [ ] Backup strategy documented
- [ ] Disaster recovery plan reviewed
- [ ] Documentation updated with URLs

## ⚠️ Important Notes and Limitations

### Script Design Principles
- **Code-Only Deployment**: Code-only scripts (`deploy-*-code.ps1`) only deploy application code, not infrastructure
- **Existing Resources Required**: All Azure resources must exist before running code-only scripts
- **No Auto-Discovery**: Resource names must be explicitly provided (no default assumptions)
- **Azure-Only**: No local development mode; use VS Code tasks for local development

### Security Considerations
- Both deployment scripts require Azure CLI authentication
- Function App uses system-assigned managed identity for AI Foundry access
- No secrets are stored in configuration files
- CORS policies restrict access to authorized origins

### Environment Configuration
- Frontend script includes hardcoded DEV environment AI Foundry settings
- Backend URL can be configured via parameter for environment-specific deployments
- Local development uses different endpoints than production

### Node.js Version Requirements
- **Required**: Node.js 20+ for all frontend development and deployment
- **Compatibility**: Vite build tool requires Node.js 20 or higher
- **Validation**: Scripts validate Node.js version before proceeding

---

## 📚 Related Documentation

- **[Infrastructure Guide](infrastructure.md)** - Understanding the architecture and resources
- **[Configuration Guide](../configuration/environment-variables.md)** - Settings and environment variables
- **[Local Development](../development/local-development.md)** - Development setup and workflows
- **[Troubleshooting](../operations/troubleshooting.md)** - Common deployment issues and solutions
- **[Azure Deployment Environments](../../documentation/AZURE_DEPLOYMENT_ENVIRONMENTS.md)** - ADE-specific implementation
- **[Multi-Resource Group Architecture](../../documentation/MULTI_RG_ARCHITECTURE.md)** - Advanced architecture patterns

---

**Ready for your first deployment?** → Return to [Quick Start](../getting-started/03-quick-start.md) for a simplified 15-minute deployment.

For questions or issues, refer to the [Troubleshooting Guide](../operations/troubleshooting.md) or check the specific documentation guides above.

---
