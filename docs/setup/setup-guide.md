# Project Setup Guide

This guide provides comprehensive setup instructions for local development and Azure deployment of the AI Foundry SPA project.

## 📋 Prerequisites

### Azure Setup
1. **[Azure Subscription](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-setup-guide/organize-resources)**: Ensure you have an active Azure subscription
2. **[Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)**: Install from official Microsoft documentation
3. **[Azure AI Foundry](https://learn.microsoft.com/en-us/azure/ai-foundry/) Resource**: Ensure you have access to an AI Foundry resource with an AI in A Box agent

### Development Tools
1. **[Node.js](https://learn.microsoft.com/en-us/windows/dev-environment/javascript/nodejs-overview) 20+**: For frontend development
2. **[.NET 8 SDK](https://learn.microsoft.com/en-us/dotnet/core/whats-new/dotnet-8)**: For backend [Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/) development
3. **[Azure Functions Core Tools](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local) v4**: For local Azure Functions development

## 🚀 Quick Start

### 1. Environment Configuration

#### Frontend Environment Setup
```bash
cd src/frontend
cp .env.example .env
```

#### Update Frontend Configuration
Edit `src/frontend/.env` with your values:
```env
# Backend Azure Functions Configuration
VITE_BACKEND_URL=http://localhost:7071/api
VITE_USE_BACKEND=true
VITE_PUBLIC_MODE=true

# Azure AI Foundry Configuration (Single Instance)
VITE_AI_FOUNDRY_AGENT_NAME=AI in A Box
VITE_AI_FOUNDRY_ENDPOINT=https://your-ai-foundry-endpoint.azureml.net
VITE_AI_FOUNDRY_DEPLOYMENT=gpt-4
```

#### Backend Configuration
```bash
cd src/backend
# Edit local.settings.json with your AI Foundry configuration
```

#### Azure Infrastructure Parameters
```bash
# Edit infra/dev-orchestrator.parameters.bicepparam
# Update Azure AI Foundry endpoint and deployment information
```

### 2. Local Development Environment

Choose from multiple development environment options:

#### Option A: Local Development
```bash
# Install frontend dependencies
cd src/frontend
npm install

# Start Azurite emulator (in a separate terminal)
azurite --silent --location .azurite

# Start Azure Functions (in a separate terminal)
cd src/backend
dotnet build
func start

# Start frontend development server (in a separate terminal)
cd src/frontend
npm run dev
```

#### Option B: VS Code Tasks (Recommended)
Use the built-in [VS Code](https://learn.microsoft.com/en-us/azure/developer/javascript/how-to/with-visual-studio-code/clone-github-repository) tasks for automated setup:
1. **Start Azurite**: Run task "Start Azurite"
2. **Start Azure Functions**: Run task "🔧 Manual Start Function App"
3. **Start Frontend**: Run task "AI Foundry SPA: Build and Run"

#### Option C: DevContainers (Recommended for consistent environment)
1. Install [Docker Desktop](https://learn.microsoft.com/en-us/dotnet/core/docker/introduction)
2. Install VS Code Dev Containers extension  
3. Open project in VS Code
4. Click "Reopen in Container" when prompted
5. Use VS Code tasks to start services

#### Option D: Azure DevBox
1. Create a DevBox in Azure
2. Use the provided `imageDefinition.yaml`
3. Clone this repository in the DevBox
4. Use VS Code tasks to start services

### 3. Development URLs

**Local Development:**
- Frontend: http://localhost:5173
- Azure Functions: http://localhost:7071
- Azure Functions Admin: http://localhost:7071/admin/functions
- Azurite Blob: http://127.0.0.1:10000
- Azurite Queue: http://127.0.0.1:10001
- Azurite Table: http://127.0.0.1:10002

**Production URLs:**
- Frontend: https://stapp-ai-foundry-spa-frontend-dev-eus2.azurestaticapps.net/
- Azure Functions: https://func-ai-foundry-spa-backend-dev-eus2.azurewebsites.net

## ☁️ Azure Deployment

### Method 1: Using Azure CLI (Recommended)

```bash
# Login to Azure CLI
az login

# Deploy infrastructure using subscription-level orchestrator
az deployment sub create \
  --location eastus \
  --template-file infra/main-orchestrator.bicep \
  --parameters infra/dev-orchestrator.parameters.bicepparam

# Deploy Azure Functions
cd src/backend
func azure functionapp publish func-ai-foundry-spa-backend-dev-eus2

# Deploy Frontend
cd ../frontend
npm run build:dev
# Use deployment script for Azure Static Web Apps
../deploy-scripts/deploy-frontend-spa-code.ps1 -StaticWebAppName "stapp-ai-foundry-spa-frontend-dev-eus2"
```

### Method 2: Using PowerShell Deployment Script

```powershell
# Login to Azure CLI
az login

# Run deployment script
./deploy-scripts/deploy.ps1
```

### Method 3: Azure Deployment Environments (ADE)

For enterprise deployments, use Azure Deployment Environments:

1. Navigate to Azure Portal → Azure Deployment Environments
2. Create a new environment using the provided catalog definitions
3. Use the ADE parameter extraction tools for CI/CD integration

See the [Azure Deployment Environments Guide](../deployment/azure-deployment-environments.md) for detailed instructions.

## 🔧 Post-Deployment Configuration

### 1. Update Frontend Environment for Production

Create `src/frontend/.env.production` with production backend URL:
```env
VITE_BACKEND_URL=https://func-ai-foundry-spa-backend-dev-eus2.azurewebsites.net/api
VITE_USE_BACKEND=true
VITE_PUBLIC_MODE=true
```

Rebuild and redeploy frontend with production configuration.

### 2. Configure Azure AI Foundry Access

- Verify Azure Functions has [Azure AI Developer role](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#azure-ai-developer) on Azure AI Foundry resource
- Confirm Azure AI Foundry endpoint configuration in Azure Functions settings

### 3. Verify Azure Static Web Apps Deployment

Azure Static Web Apps should be automatically configured - no manual configuration needed as it's handled by the deployment script.

## ✅ Verification and Testing

### 1. Test Local Development

```bash
# Frontend should be available at:
http://localhost:5173 (or 5174 if 5173 is in use)

# Azure Functions should be available at:
http://localhost:7071
```

### 2. Test Production Deployment

- Visit your Azure Static Web Apps URL
- Test AI conversation functionality
- Verify Azure Functions endpoints respond correctly

### 3. Run Endpoint Tests

```bash
# Test local endpoints
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "http://localhost:7071"

# Test Azure endpoints
./tests/core/Test-FunctionEndpoints.ps1 -BaseUrl "https://func-ai-foundry-spa-backend-dev-eus2.azurewebsites.net"
```

### 4. Verify Docker Installation (DevContainer/DevBox)

```bash
# Check Docker installation
docker --version

# Test Docker functionality
docker run hello-world
```

## 🔍 Troubleshooting

### Common Issues

#### Azure Functions Connection Failed
- Verify Azure Functions is running locally or deployed to Azure
- Check [CORS configuration](https://learn.microsoft.com/en-us/azure/azure-functions/functions-how-to-use-azure-function-app-settings#cors) allows frontend domain
- Ensure Azure AI Foundry configuration is correct in Azure Functions settings

#### Azure AI Foundry Connection Failed
- Verify Azure AI Foundry endpoint URLs and deployment names
- Check Azure Functions has Azure AI Developer role on Azure AI Foundry resource
- Ensure network connectivity from Azure Functions to Azure AI Foundry

#### Build Failed
- Verify Node.js version (20+ required)
- Clear npm cache: `npm cache clean --force`
- Delete node_modules and reinstall: `rm -rf node_modules && npm install`

#### Deployment Failed
- Check Azure CLI authentication: `az account show`
- Verify subscription permissions
- Check resource naming conflicts
- Ensure Azure Bicep file is valid: `az bicep build --file infra/main-orchestrator.bicep`

#### Azurite Issues
- Check ports 10000, 10001, 10002 are not in use
- Delete `.azurite` folder and restart
- Install Azurite globally: `npm install -g azurite`

For comprehensive troubleshooting, see the [Troubleshooting Guide](../operations/troubleshooting.md).

## 📚 Next Steps

### Configure Monitoring
[Application Insights](https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview) is pre-configured for monitoring and diagnostics.

### Security
- Review CORS settings and Azure Functions access controls
- Configure authentication if needed
- Review Azure AI Foundry access permissions

### Scaling
Consider [Azure CDN](https://learn.microsoft.com/en-us/azure/cdn/) for global distribution of static assets.

### Testing
- Use the PowerShell test scripts to validate functionality
- Set up automated testing in CI/CD pipelines
- Monitor application performance and errors

## 🆘 Support

For issues and questions:

1. Check the troubleshooting section above
2. Review the [comprehensive troubleshooting guide](../operations/troubleshooting.md)
3. Check Azure documentation links in the main README.md
4. Use the provided test scripts to diagnose issues
5. Check Azure Functions logs in [Azure Portal](https://learn.microsoft.com/en-us/azure/azure-portal/)

## 📖 Related Documentation

- **[Quick Start Guide](../getting-started/03-quick-start.md)** - Fastest way to get started
- **[Deployment Guide](../deployment/deployment-guide.md)** - Comprehensive deployment options
- **[Local Development Guide](../development/local-development.md)** - Detailed development setup
- **[Azure Deployment Environments](../deployment/azure-deployment-environments.md)** - ADE-specific setup
- **[Configuration Reference](../configuration/configuration-reference.md)** - All configuration options
- **[Troubleshooting Guide](../operations/troubleshooting.md)** - Problem resolution
