# Development Guide

This guide covers local development setup, workflows, and best practices for the [Azure AI Foundry](https://learn.microsoft.com/en-us/azure/ai-foundry/) SPA project.

## 🛠️ Development Setup

### Prerequisites
- **[Node.js](https://learn.microsoft.com/en-us/windows/dev-environment/javascript/nodejs-overview) 20+** and npm (for frontend development)
- **[.NET 8 SDK](https://learn.microsoft.com/en-us/dotnet/core/whats-new/dotnet-8)** (for backend [Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/) development)
- **[Azure CLI](https://learn.microsoft.com/en-us/cli/azure/)** with [Azure Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/) and DevCenter extensions
- **[Azure Functions Core Tools](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local) v4** (for local Azure Functions development)
- **[Python](https://learn.microsoft.com/en-us/azure/developer/python/) 3.12+** (for development tooling and scripting, optional)
- **[Azure subscription](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-setup-guide/organize-resources)** with appropriate permissions

### Installation Commands

#### Windows
```powershell
# Node.js (using winget)
winget install OpenJS.NodeJS.LTS

# .NET 8 SDK
winget install Microsoft.DotNet.SDK.8

# Azure CLI
winget install Microsoft.AzureCLI

# Azure Functions Core Tools
winget install Microsoft.Azure.FunctionsCoreTools
# OR via npm
npm install -g azure-functions-core-tools@4 --unsafe-perm true

# Python (optional, for development tooling)
winget install Python.Python.3.12

# Install Azure Bicep
az bicep install
az extension add --name bicep
```

#### macOS
```bash
# Node.js (using Homebrew)
brew install node@20

# .NET 8 SDK
brew install --cask dotnet-sdk

# Azure CLI
brew install azure-cli

# Azure Functions Core Tools
brew tap azure/functions
brew install azure-functions-core-tools@4

# Python (optional, for development tooling)
brew install python@3.12

# Install Azure Bicep
az bicep install
az extension add --name bicep
```

#### Linux (Ubuntu/Debian)
```bash
# Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# .NET 8 SDK
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update && sudo apt-get install -y dotnet-sdk-8.0

# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Azure Functions Core Tools
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-$(lsb_release -cs)-prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/dotnetdev.list'
sudo apt-get update && sudo apt-get install azure-functions-core-tools-4

# Python (optional, for development tooling)
sudo apt-get update && sudo apt-get install -y python3.12 python3.12-pip python3.12-venv

# Install Azure Bicep
az bicep install
az extension add --name bicep
```

## 🚀 Available Scripts

### Frontend Scripts
```bash
cd src/frontend

# Development server with hot reload
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Clean build artifacts
npm run clean
```

### Backend Scripts
```bash
cd src/backend

# Build the Azure Functions
dotnet build

# Run locally with hot reload
func start

# Clean build artifacts
dotnet clean
```

### Infrastructure Scripts
```bash
# Deploy complete infrastructure (if needed)
az deployment sub create --template-file infra/main-orchestrator.bicep --parameters infra/dev-orchestrator.parameters.bicepparam --location eastus2

# For [Azure Deployment Environments (ADE)](https://learn.microsoft.com/en-us/azure/deployment-environments/), use the ADE portal or CLI
```

### Code-Only Deployment Scripts (Post-Infrastructure)

Two specialized scripts handle application code deployment to **existing** Azure infrastructure:

```powershell
# Deploy backend code to existing Function App
./deploy-scripts/deploy-backend-func-code.ps1 -FunctionAppName "func-name" -ResourceGroupName "rg-name"

# Deploy frontend code to existing Static Web App
./deploy-scripts/deploy-frontend-spa-code.ps1 -StaticWebAppName "swa-name" -ResourceGroupName "rg-name"
```

> **⚠️ Important**: These scripts are for **code-only deployment** to existing Azure resources. Infrastructure must be deployed first through ADE, Bicep, or CI/CD pipelines.

### Legacy Complete Deployment Script
```powershell
# Complete deployment (infrastructure + code) - for greenfield scenarios
./deploy-scripts/deploy.ps1
```

## 📦 Deployment Workflows

### 🎯 Code-Only Deployment (Recommended for ADE)

When infrastructure is already deployed (via ADE or Azure Bicep), use these simplified scripts to deploy application code:

#### Backend Code Deployment
```powershell
# Required parameters (no defaults or auto-detection)
./deploy-scripts/deploy-backend-func-code.ps1 `
    -FunctionAppName "func-ai-foundry-spa-backend-dev-eus2" `
    -ResourceGroupName "rg-ai-foundry-spa-backend-dev-eus2"

# Optional parameters
./deploy-scripts/deploy-backend-func-code.ps1 `
    -FunctionAppName "func-ai-foundry-spa-backend-dev-eus2" `
    -ResourceGroupName "rg-ai-foundry-spa-backend-dev-eus2" `
    -SkipBuild `
    -SkipTest
```

**What it does:**
- ✅ Validates Azure CLI authentication
- ✅ Verifies Azure Functions exists in specified resource group
- ✅ Builds .NET Azure Functions (unless `-SkipBuild`)
- ✅ Creates deployment package and deploys to Azure
- ✅ Tests health endpoint (unless `-SkipTest`)
- ✅ Provides deployment summary with URLs

#### Frontend Code Deployment
```powershell
# Required parameters (no defaults or auto-detection)
./deploy-scripts/deploy-frontend-spa-code.ps1 `
    -StaticWebAppName "stapp-aibox-fd-dev-eus2" `
    -ResourceGroupName "rg-ai-foundry-spa-frontend-dev-eus2"

# With backend URL configuration
./deploy-scripts/deploy-frontend-spa-code.ps1 `
    -StaticWebAppName "stapp-aibox-fd-dev-eus2" `
    -ResourceGroupName "rg-ai-foundry-spa-frontend-dev-eus2" `
    -BackendUrl "https://func-ai-foundry-spa-backend-dev-eus2.azurewebsites.net/api"

# Skip build if already built
./deploy-scripts/deploy-frontend-spa-code.ps1 `
    -StaticWebAppName "stapp-aibox-fd-dev-eus2" `
    -ResourceGroupName "rg-ai-foundry-spa-frontend-dev-eus2" `
    -SkipBuild
```

**What it does:**
- ✅ Validates Azure CLI authentication
- ✅ Verifies Azure Static Web Apps exists in specified resource group
- ✅ Creates DEV environment configuration with hardcoded Azure AI Foundry settings
- ✅ Builds frontend application (unless `-SkipBuild`)
- ✅ Installs [SWA CLI](https://learn.microsoft.com/en-us/azure/static-web-apps/static-web-apps-cli-overview) if needed and deploys to Azure Static Web Apps
- ✅ Provides deployment summary with URLs

### 🏗️ Complete Infrastructure + Code Deployment

For greenfield deployments or when infrastructure changes are needed:

```powershell
# Deploy everything (infrastructure + code)
./deploy-scripts/deploy.ps1
```

### 🔍 Finding Resource Names for ADE Environments

When working with [Azure Deployment Environments](https://learn.microsoft.com/en-us/azure/deployment-environments/), you'll need to discover the resource names:

#### Method 1: [Azure Portal](https://learn.microsoft.com/en-us/azure/azure-portal/)
1. Navigate to your ADE environment
2. Go to "Resources" tab
3. Note the Azure Functions and Azure Static Web Apps names

#### Method 2: Azure CLI
```bash
# List Function Apps in a resource group
az functionapp list --resource-group "rg-name" --query "[].{name:name,state:state}" --output table

# List Static Web Apps in a resource group
az staticwebapp list --resource-group "rg-name" --query "[].{name:name,defaultHostname:defaultHostname}" --output table

# Search by resource type across subscription
az resource list --resource-type "Microsoft.Web/sites" --query "[?kind=='functionapp'].{name:name,resourceGroup:resourceGroup}" --output table
az resource list --resource-type "Microsoft.Web/staticSites" --query "[].{name:name,resourceGroup:resourceGroup}" --output table
```

### 🎨 Development vs Deployment

| Task | Tool | Purpose | Infrastructure Required |
|------|------|---------|------------------------|
| **Local Frontend Development** | `npm run dev` | Hot reload, debugging | None (local only) |
| **Local Backend Development** | `func start` or VS Code tasks | Function testing | Azurite (local storage) |
| **Frontend Code Deployment** | `deploy-frontend-spa-code.ps1` | Deploy SPA to existing Azure Static Web App | ✅ Static Web App must exist |
| **Backend Code Deployment** | `deploy-backend-func-code.ps1` | Deploy Function App to existing Azure infrastructure | ✅ Function App must exist |
| **Complete Deployment** | `deploy.ps1` | Infrastructure + code (legacy/greenfield) | Creates infrastructure |
| **Infrastructure Only** | Azure CLI + Bicep or ADE | Resource provisioning | Creates all resources |

### ⚠️ Important Notes

- **🏠 Local Development**: Use `npm run dev` and `func start` for local development and testing
- **☁️ Code-Only Scripts**: Deployment scripts are for existing Azure infrastructure only
- **🏗️ Infrastructure First**: Deploy infrastructure through ADE, Bicep, or CI/CD before deploying code
- **📋 Explicit Parameters**: Scripts require exact resource names - no auto-detection or defaults
- **🎯 ADE Compatible**: Designed to work with Azure Deployment Environment provisioned resources
- **⚙️ Environment Configuration**: Frontend script includes hardcoded DEV environment AI Foundry settings

## 🔧 Local Development Storage with Azurite

For local development, the backend Function App uses **Azurite** to emulate Azure Storage services.

### VS Code Tasks
Use the predefined VS Code tasks for streamlined development:

1. **Start Azurite**: `Ctrl+Shift+P` → "Tasks: Run Task" → "Start Azurite"
2. **Build and Start Function App**: `Ctrl+Shift+P` → "Tasks: Run Task" → "🔧 Manual Start Function App"
3. **Start Frontend**: `Ctrl+Shift+P` → "Tasks: Run Task" → "AI Foundry SPA: Build and Run"

### Manual Setup
```bash
# Install Azurite globally
npm install -g azurite

# Start Azurite in background
azurite --silent --location .azurite

# Start Function App
cd src/backend
func start --verbose

# Start Frontend (in new terminal)
cd src/frontend
npm run dev
```

## 🌐 Environment Variables

### Frontend Environment Variables
Create `src/frontend/environments/local.js` for local development:

```javascript
export const environment = {
  production: false,
  apiBaseUrl: 'http://localhost:7071',
  aiFoundryEndpoint: 'your-ai-foundry-endpoint',
  agentName: 'AI in A Box'
};
```

### Backend Environment Variables
Update `src/backend/local.settings.json`:

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
    "AI_FOUNDRY_ENDPOINT": "your-ai-foundry-endpoint-url",
    "AI_FOUNDRY_DEPLOYMENT": "your-deployment-name",
    "AI_FOUNDRY_AGENT_NAME": "AI in A Box"
  }
}
```

## 🔍 Debugging and Troubleshooting

### Common Issues

#### Function App Won't Start
1. Ensure Azurite is running
2. Check that .NET 8 SDK is installed
3. Verify `local.settings.json` configuration
4. Try cleaning and rebuilding: `dotnet clean && dotnet build`

#### Frontend Build Fails
1. Ensure Node.js 20+ is installed
2. Clear npm cache: `npm cache clean --force`
3. Delete node_modules and reinstall: `rm -rf node_modules && npm install`

#### CORS Issues
For local development, the backend Function App is configured to allow CORS from localhost:5173.

### Development Workflow

1. **Start Azurite** (storage emulator)
2. **Start Backend** (Function App on port 7071)
3. **Start Frontend** (Vite dev server on port 5173)
4. **Open Browser** to http://localhost:5173
5. **Make Changes** - both frontend and backend support hot reload

## 📱 DevContainer Support

The project includes a DevContainer configuration for consistent development environments:

```bash
# Open in DevContainer
code .
# VS Code will prompt to reopen in container
```

The DevContainer automatically:
- Installs Node.js 20, .NET 8 SDK, Azure CLI with extensions, and Azure Functions Core Tools
- Configures Docker-in-Docker for containerized development workflows
- Configures VS Code extensions for Bicep, Azure Functions, C#, and Docker
- Sets up port forwarding for development servers (5173, 4173, 7071)
- Runs `npm install` in the frontend directory and configures Azure tooling
- Validates Docker installation with `docker --version`

### Docker in DevContainer
The DevContainer includes Docker-in-Docker support for:
- Running Azurite in containers instead of local installation
- Testing Function Apps in containerized environments
- Building and testing container images locally

## 🏗️ DevBox Support

For team development environments, use the DevBox configuration:

```powershell
# DevBox includes all tools and extensions automatically
# See devbox/README.md for detailed setup instructions

# Validate your DevBox setup
.\devbox\Test-DevBoxSetup.ps1

# Or run detailed validation
.\devbox\Test-DevBoxSetup.ps1 -Detailed
```

The DevBox configuration automatically installs:
- All required development tools (Node.js, .NET, Azure CLI with extensions, Python)
- Docker Desktop for containerized development workflows
- VS Code with pre-configured extensions including GitHub Copilot and Docker tools
- Azure Functions Core Tools and Azurite
- Azure CLI extensions (Bicep and DevCenter) and Azure AI Toolkit

### Docker in DevBox
The DevBox includes Docker Desktop for:
- Running Azurite and other services in containers
- Function App containerized testing and development
- Consistent development environment isolation

See [DevBox README](../devbox/README.md) for detailed setup instructions and troubleshooting.

## 🧪 Testing

### Frontend Testing
```bash
# Navigate to frontend directory
cd src/frontend

# Install testing dependencies
npm install

# Run unit tests
npm test

# Run tests with coverage
npm run test:coverage

# Run tests in watch mode (for development)
npm run test:watch
```

### Manual Testing
```bash
# Test Function App endpoints
./tests/Test-FunctionEndpoints.ps1 -BaseUrl "http://localhost:7071"

# Test Azure deployment
./tests/Test-FunctionEndpoints.ps1 -BaseUrl "https://your-function-app.azurewebsites.net"
```

### Test Scripts
- `Test-FunctionEndpoints.ps1`: Validates Function App endpoints
- `Test-FunctionAppAccess.ps1`: Tests Function App accessibility
- `Test-AzuriteSetup.ps1`: Validates Azurite configuration

### Testing Best Practices
⚠️ **Important**: Always test locally before deployment. The test suite includes:
- **Unit Tests**: Test individual functions with mocks
- **Integration Tests**: Test workflows and data flow
- **Manual Tests**: Validate actual deployments

**Critical Testing Gap Addressed**: After discovering a runtime error where event handlers referenced non-existent methods, we've enhanced testing to include:
- Class instantiation validation
- Event binding verification  
- Method existence checks

See [Test Documentation](../tests/TEST.md) for comprehensive testing information.

## 🔗 Related Documentation

- [Setup Guide](SETUP.md) - Initial project setup
- [Public Mode Setup](PUBLIC_MODE_SETUP.md) - Authentication configuration
- [Multi-RG Architecture](MULTI_RG_ARCHITECTURE.md) - Infrastructure design
- [Thread Persistence Fix](THREAD_PERSISTENCE_FIX.md) - Conversation state handling
- [AI Foundry Browser Limitations](AI_FOUNDRY_BROWSER_LIMITATIONS.md) - Browser compatibility
