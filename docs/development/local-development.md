# Development Guide

*Comprehensive guide for local development setup, workflows, and best practices for the Azure AI Foundry SPA project.*

## 🎯 Overview

This guide helps you set up a local development environment where you can:
- Run the frontend and backend locally
- Make changes and see them immediately
- Test integrations with Azure AI Foundry
- Debug issues before deploying to Azure
- Understand the development workflows and tooling

## 🛠️ Development Setup

### Prerequisites

**Required Tools:**
- **[Node.js 20+](https://nodejs.org/)** and npm (for frontend development)
- **[.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)** (for backend Azure Functions development)
- **[Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)** with Azure Bicep and DevCenter extensions
- **[Azure Functions Core Tools v4](https://docs.microsoft.com/azure/azure-functions/functions-run-local)** (for local Azure Functions development)
- **[Git](https://git-scm.com/)** (for version control)

**Optional Tools:**
- **[Visual Studio Code](https://code.visualstudio.com/)** - Recommended editor
- **[Azure Tools Extension Pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-node-azure-pack)** - VS Code extensions
- **[Azurite](https://docs.microsoft.com/azure/storage/common/storage-use-azurite)** - Local storage emulator
- **[Python 3.12+](https://www.python.org/)** (for development tooling and scripting, optional)

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

### Verification
```bash
# Verify installations
node --version      # Should be 20.0+ or later
npm --version       # Should be 9.0+ or later
dotnet --version    # Should be 8.0+ or later
func --version      # Should be 4.0+ or later
az --version        # Should be 2.50+ or later
git --version       # Any recent version
```

## 🏗️ Project Setup

### 1. Clone and Navigate

```bash
# Clone the repository
git clone https://github.com/JFolberth/ai-in-a-box.git
cd ai-in-a-box
```

### 2. Backend Setup

```bash
# Navigate to backend
cd src/backend

# Restore dependencies
dotnet restore

# Create local settings file
cp local.settings.json.example local.settings.json
```

### 3. Configure Backend Settings

Edit `src/backend/local.settings.json`:

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
    "AI_FOUNDRY_ENDPOINT": "https://your-ai-foundry.cognitiveservices.azure.com/",
    "AI_FOUNDRY_DEPLOYMENT": "gpt-4",
    "AI_FOUNDRY_AGENT_NAME": "AI in A Box",
    "APPLICATIONINSIGHTS_CONNECTION_STRING": "InstrumentationKey=your-key-here"
  }
}
```

### 4. Frontend Setup

```bash
# Navigate to frontend
cd ../frontend

# Install dependencies
npm install

# Create environment file
cp .env.example .env.local
```

### 5. Configure Frontend Settings

Edit `src/frontend/.env.local`:

```env
# Backend Configuration
VITE_BACKEND_URL=http://localhost:7071/api
VITE_USE_BACKEND=true
VITE_PUBLIC_MODE=true

# AI Foundry Configuration
VITE_AI_FOUNDRY_AGENT_NAME=AI in A Box
VITE_AI_FOUNDRY_ENDPOINT=https://your-ai-foundry.cognitiveservices.azure.com/
VITE_AI_FOUNDRY_DEPLOYMENT=gpt-4

# Development Settings
VITE_DEBUG_LOGGING=true
```

## 🚀 Running Locally

### Option 1: Manual Startup (Recommended for Development)

**Terminal 1 - Backend:**
```bash
cd src/backend

# Start Azurite (local storage emulator)
azurite --silent --location /tmp/azurite --debug /tmp/azurite/debug.log &

# Start Functions host
func start --port 7071
```

**Terminal 2 - Frontend:**
```bash
cd src/frontend

# Start development server
npm run dev
```

### Option 2: VS Code Integrated Setup

If using VS Code, you can use the included tasks:

1. **Open VS Code** in the project root
2. **Open Command Palette** (Ctrl/Cmd + Shift + P)
3. **Run Task**: `Tasks: Run Task`
4. **Select**: `Start Local Development`

This will start both frontend and backend simultaneously.

## 📦 Deployment Scripts

Beyond local development, the project includes specialized deployment scripts for different scenarios:

### Available Scripts

#### Frontend Scripts
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

#### Backend Scripts
```bash
cd src/backend

# Build the Azure Functions
dotnet build

# Run locally with hot reload
func start

# Clean build artifacts
dotnet clean
```

### Code-Only Deployment (Recommended for ADE)

When infrastructure is already deployed (via Azure Deployment Environments or Azure Bicep), use these simplified scripts to deploy application code:

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

### Complete Infrastructure + Code Deployment

For greenfield deployments or when infrastructure changes are needed:

```powershell
# Deploy everything (infrastructure + code)
./deploy-scripts/deploy-quickstart.ps1
```

### 🔍 Finding Resource Names for ADE Environments

When working with [Azure Deployment Environments](https://learn.microsoft.com/en-us/azure/deployment-environments/), you'll need to discover the resource names:

#### Method 1: Azure Portal
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

### Development vs Deployment Reference

| Task | Tool | Purpose | Infrastructure Required |
|------|------|---------|------------------------|
| **Local Frontend Development** | `npm run dev` | Hot reload, debugging | None (local only) |
| **Local Backend Development** | `func start` or VS Code tasks | Function testing | Azurite (local storage) |
| **Frontend Code Deployment** | `deploy-frontend-spa-code.ps1` | Deploy SPA to existing Azure Static Web App | ✅ Static Web App must exist |
| **Backend Code Deployment** | `deploy-backend-func-code.ps1` | Deploy Function App to existing Azure infrastructure | ✅ Function App must exist |
| **Complete Deployment** | `deploy-quickstart.ps1` | Infrastructure + code (automated deployment) | Creates infrastructure |
| **Infrastructure Only** | Azure CLI + Bicep or ADE | Resource provisioning | Creates all resources |

### ⚠️ Important Deployment Notes

- **🏠 Local Development**: Use `npm run dev` and `func start` for local development and testing
- **☁️ Code-Only Scripts**: Deployment scripts are for existing Azure infrastructure only
- **🏗️ Infrastructure First**: Deploy infrastructure through ADE, Bicep, or CI/CD before deploying code
- **📋 Explicit Parameters**: Scripts require exact resource names - no auto-detection or defaults
- **🎯 ADE Compatible**: Designed to work with Azure Deployment Environment provisioned resources
- **⚙️ Environment Configuration**: Frontend script includes hardcoded DEV environment AI Foundry settings

---

## 🔧 Development Workflow

### Making Changes

**Frontend Changes:**
- Edit files in `src/frontend/`
- Changes auto-reload in browser (hot reload)
- Check browser console for errors

**Backend Changes:**
- Edit files in `src/backend/`
- Functions host automatically reloads
- Check terminal output for errors

### Testing Changes

**Frontend Testing:**
```bash
cd src/frontend

# Run unit tests
npm test

# Run tests with coverage
npm run test:coverage

# Run tests in watch mode
npm run test:watch
```

**Backend Testing:**
```bash
cd src/backend

# Run all tests
dotnet test

# Run with detailed output
dotnet test --verbosity normal

# Run specific test
dotnet test --filter "TestMethodName"
```

### Debugging

**Frontend Debugging:**
- Use browser dev tools (F12)
- Set breakpoints in Sources tab
- Check Network tab for API calls
- View Console for errors and logs

**Backend Debugging:**
- Use VS Code debugger with F5
- Set breakpoints in C# code
- Use Azure Functions Core Tools logs
- Check local storage emulator logs

## 🌐 Local URLs

When running locally, your application will be available at:

- **Frontend**: `http://localhost:5173` (or next available port)
- **Backend**: `http://localhost:7071`
- **Health Check**: `http://localhost:7071/api/health`
- **API Base**: `http://localhost:7071/api`

## 🔍 Verification

### Test Local Setup

1. **Check Backend Health:**
```bash
curl http://localhost:7071/api/health
```

2. **Test Frontend Connection:**
- Open `http://localhost:5173` in browser
- Send a test message
- Verify response from AI

3. **Check Integration:**
- Messages should flow: Frontend → Backend → AI Foundry → Backend → Frontend
- Browser network tab should show calls to `localhost:7071`
- Backend terminal should show request logs

## 🚨 Common Issues

### Issue: "Az command not found"
**Solution:**
```bash
# Install Azure CLI
# Windows: Download from Microsoft
# macOS: brew install azure-cli
# Linux: See Azure CLI installation guide
```

### Issue: "Func command not found"
**Solution:**
```bash
npm install -g azure-functions-core-tools@4 --unsafe-perm true
```

### Issue: "AI Foundry connection failed"
**Solutions:**
1. **Check endpoint URL** in `local.settings.json`
2. **Verify Azure login**: `az login`
3. **Check AI Foundry permissions** - ensure you have access
4. **Test connection**: Use health endpoint

### Issue: "CORS errors in browser"
**Solution:**
```bash
# Backend should allow frontend origin
# Check that VITE_BACKEND_URL matches function URL
# Verify CORS configuration in Function App
```

### Issue: "Port already in use"
**Solutions:**
```bash
# Kill processes on ports
lsof -ti:7071 | xargs kill  # Backend
lsof -ti:5173 | xargs kill  # Frontend

# Or use different ports
func start --port 7072      # Backend on different port
npm run dev -- --port 5174  # Frontend on different port
```

## 📁 Project Structure

Understanding the codebase structure helps with development:

```
ai-in-a-box/
├── src/
│   ├── frontend/              # JavaScript SPA
│   │   ├── src/              # Source code
│   │   ├── public/           # Static assets
│   │   ├── tests/            # Unit tests
│   │   └── package.json      # Dependencies
│   └── backend/              # C# Azure Functions
│       ├── Functions/        # Function endpoints
│       ├── Models/           # Data models
│       ├── Services/         # Business logic
│       └── Tests/            # Unit tests
├── infra/                    # Bicep infrastructure
├── deploy-scripts/           # Deployment scripts
└── docs/                     # Documentation
```

## 🔗 Next Steps

Once your local environment is working:

1. **[Project Structure](project-structure.md)** - Understand the codebase
2. **[Testing Guide](testing-guide.md)** - Run comprehensive tests
3. **[Debugging Guide](debugging.md)** - Troubleshoot issues
4. **[Customization](../configuration/customization.md)** - Make it your own

## 📖 Related Documentation

- **[Configuration](../configuration/environment-variables.md)** - Environment variable reference
- **[Troubleshooting](../operations/troubleshooting.md)** - Common issues and solutions
- **[Deployment](../deployment/deployment-guide.md)** - Deploy your changes

---

**Ready to start developing?** Your local environment should now be ready for customization and development!