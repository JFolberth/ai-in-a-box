# Deployment Guide

*Comprehensive guide for deploying the AI Foundry SPA to production environments.*

## 🎯 Overview

This guide covers production deployment scenarios, from single environment deployments to multi-environment CI/CD pipelines. Choose the deployment method that best fits your organization's needs.

## 🚀 Deployment Options

### 1. **Quick Start Script** (Local Development Only)
- **Best for**: Learning, development, testing
- **Effort**: ~15 minutes automated deployment
- **Skills needed**: Basic PowerShell, Azure CLI
- **⚠️ Important**: Uses defaults from `main-orchestrator.bicep`, NOT the `.bicepparam` file

### 2. **Manual Azure CLI Deployment** (Recommended for getting started)
- **Best for**: Learning, development, small teams
- **Effort**: ~30 minutes for first deployment
- **Skills needed**: Basic Azure CLI, command line
- **Uses**: `.bicepparam` parameter files for configuration

### 3. **Azure Deployment Environments (ADE)** 
- **Best for**: Enterprise teams, standardized deployments
- **Effort**: ~1 hour for initial setup, then 15 minutes per deployment
- **Skills needed**: Azure portal navigation, ADE concepts
- **Uses**: `.bicepparam` parameter files for configuration

### 4. **GitHub Actions CI/CD** (Automated)
- **Best for**: Teams with ongoing development, production systems
- **Effort**: ~2 hours for pipeline setup, then automatic
- **Skills needed**: GitHub Actions, CI/CD concepts
- **Uses**: `.bicepparam` parameter files for configuration

### 5. **Code-Only Deployment** (Existing infrastructure)
- **Best for**: Updates to existing deployments
- **Effort**: ~10 minutes per deployment
- **Skills needed**: PowerShell, Azure CLI

## 📋 Parameter Configuration

**Quick Start Script vs Parameter Files:**

- **Quick Start Script** (`deploy-quickstart.ps1`): Uses default values from `main-orchestrator.bicep` parameters. Interactive prompts override defaults. Does NOT use `.bicepparam` files.

- **CI/CD & Manual Deployments**: Use `.bicepparam` parameter files for configuration. These files override the defaults in `main-orchestrator.bicep`.

**Configuration Priority:**
1. Quick Start Script: Interactive prompts → `main-orchestrator.bicep` defaults
2. CI/CD/Manual: `.bicepparam` files → `main-orchestrator.bicep` defaults

## 🔧 Method 1: Quick Start Script (Local Development)

### Prerequisites
- Azure CLI installed and logged in
- PowerShell Core installed
- Azure subscription with Contributor permissions
- Git repository cloned locally

### Usage
```powershell
# Navigate to project directory
cd /path/to/ai-in-a-box

# Run quick start deployment
./deploy-scripts/deploy-quickstart.ps1

# Or with specific parameters
./deploy-scripts/deploy-quickstart.ps1 -Location "eastus2" -ApplicationName "myapp" -InteractiveMode:$false
```

**⚠️ Important Notes:**
- Quick start script uses defaults from `main-orchestrator.bicep`, NOT parameter files
- Designed for local development and testing only
- For production deployments, use CI/CD or manual deployment methods

## 🔧 Method 2: Manual Azure CLI Deployment

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

// Required: Your existing AI Foundry configuration (must exist before deployment)
param aiFoundryResourceGroupName = 'rg-your-ai-foundry'
param aiFoundryResourceName = 'your-ai-foundry-resource'
param aiFoundryProjectName = 'firstProject'
param aiFoundryEndpoint = 'https://your-production-ai-foundry.cognitiveservices.azure.com/'
param aiFoundryModelDeploymentName = 'gpt-4.1-mini'
param aiFoundryAgentName = 'AI in A Box'

// Required: Your user principal ID
param userPrincipalId = 'your-user-principal-id'

// Environment settings  
param environmentName = 'prod'
param location = 'eastus2'
param applicationName = 'ai-foundry-spa'

// Optional: Custom domain for production
param customDomainName = 'ai.yourcompany.com'  // Optional
```

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

## 🏢 Method 2: Azure Deployment Environments (ADE)

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
# Deploy backend code
./deploy-scripts/deploy-backend-func-code.ps1 `
  -FunctionAppName "func-ai-foundry-spa-backend-prod-xyz" `
  -ResourceGroupName "rg-ai-foundry-spa-backend-prod-eus2"

# Deploy frontend code  
./deploy-scripts/deploy-frontend-spa-code.ps1 `
  -StaticWebAppName "stapp-ai-foundry-spa-frontend-prod-xyz" `
  -ResourceGroupName "rg-ai-foundry-spa-frontend-prod-eus2"
```

## 🔄 Method 3: GitHub Actions CI/CD

### Prerequisites
- GitHub repository with the code
- Azure service principal configured
- GitHub secrets configured

### Step 1: Configure GitHub Secrets

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

### Step 2: Enable GitHub Actions

The repository includes a complete CI/CD pipeline in `.github/workflows/`. To enable:

1. **Push to main branch** triggers automatic deployment
2. **Review workflow** in GitHub Actions tab
3. **Monitor deployment** progress in real-time

### Step 3: Customize Workflow (Optional)

Edit `.github/workflows/deploy.yml` for your specific needs:

```yaml
# Customize deployment targets
env:
  AZURE_LOCATION: 'eastus2'
  ENVIRONMENT_NAME: 'prod'
  
# Add additional environments
deploy-staging:
  if: github.ref == 'refs/heads/develop'
  # ... staging deployment steps
```

## 🔁 Method 4: Code-Only Deployment

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

## 🔒 Production Considerations

### Security Hardening

**Network Security:**
```bash
# Configure advanced security features
az functionapp config set \
  --name "$FUNCTION_APP_NAME" \
  --resource-group "$FUNCTION_RG" \
  --ftps-state Disabled \
  --min-tls-version 1.2
```

**Access Control:**
```bash
# Restrict Function App access
az functionapp config access-restriction add \
  --name "$FUNCTION_APP_NAME" \
  --resource-group "$FUNCTION_RG" \
  --rule-name "AllowFrontendOnly" \
  --action Allow \
  --ip-address "$FRONTEND_IP_RANGE"
```

### Monitoring Setup

**Application Insights:**
```bash
# Configure detailed monitoring
az monitor app-insights component create \
  --app "$APP_INSIGHTS_NAME" \
  --location "$LOCATION" \
  --resource-group "$RG_NAME" \
  --kind web \
  --retention-time 365
```

**Alerts:**
```bash
# Create health check alert
az monitor metrics alert create \
  --name "AI-Foundry-SPA-Health" \
  --resource-group "$FUNCTION_RG" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$FUNCTION_RG/providers/Microsoft.Web/sites/$FUNCTION_APP_NAME" \
  --condition "count requests < 1" \
  --window-size 5m \
  --evaluation-frequency 1m
```

### Backup and Recovery

**Configuration Backup:**
```bash
# Export resource configurations
az resource list \
  --resource-group "$RG_NAME" \
  --query "[].{name:name, type:type, location:location}" \
  --output json > backup-config.json
```

**Data Backup:**
- Application Insights data (30-365 days retention)
- Function App code (stored in Git repository)
- Configuration settings (exported via Azure CLI)

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

## 🔗 Related Documentation

- **[Infrastructure Guide](infrastructure.md)** - Understanding the architecture
- **[Multi-Environment Setup](multi-environment.md)** - Environment management
- **[Configuration Guide](../configuration/environment-variables.md)** - Settings and variables
- **[Troubleshooting](../operations/troubleshooting.md)** - Common deployment issues

---

**Ready for your first deployment?** → Return to [Quick Start](../getting-started/03-quick-start.md) for a simplified 15-minute deployment.